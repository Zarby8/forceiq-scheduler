import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import assert from "node:assert/strict";
import { CANARY_SECRET, residue, SENSITIVE_PROMPT } from "./canaries.mjs";
import {
  approveCandidate,
  appendCapture,
  demonstrateCapture,
  demonstrateUpstreamHook,
  loadPolicy,
  recordProductTruth,
  redactText,
  repoRoot,
  scoreEvaluation,
} from "./lib.mjs";

const policy = loadPolicy();

function jev(overrides = {}) {
  return {
    model: "jev-1.13.0",
    gate: "auto",
    answers: {
      task_success: { noul: 0.91 },
      reusable_correction: { noul: 0.88 },
      evidence_supported: { noul: 0.84 },
      auto_promote: { noul: 0.97 },
      redaction_holds: { noul: 0.93 },
      logs_alone_sufficient: { noul: 0.04 },
      ...overrides,
    },
  };
}

const safeTrace = JSON.parse(fs.readFileSync(path.join(repoRoot, "beacon/fixtures/safe-trace.json"), "utf8"));

test("redacts secrets, clients, and appointment times", () => {
  const redacted = redactText(`${SENSITIVE_PROMPT}\nsession at 5:00 PM on 2026-09-22`);
  assert.equal(residue(redacted), false);
  assert.match(redacted, /\[REDACTED\]/);
  assert.equal(redactText("timeout stays 30 seconds and beacon 1.3.18"), "timeout stays 30 seconds and beacon 1.3.18");
});

test("redaction is idempotent", () => {
  const once = redactText(SENSITIVE_PROMPT);
  assert.equal(redactText(once), once);
});

test("capture keeps a redacted hook payload and drops a foreign transcript", () => {
  const logPath = path.join(os.tmpdir(), `beacon-test-${process.pid}.jsonl`);
  fs.rmSync(logPath, { force: true });
  const kept = appendCapture(JSON.stringify({ conversation_id: "c1", prompt: SENSITIVE_PROMPT }), {
    harness: "cursor",
    event: "prompt-submit",
    logPath,
  });
  const dropped = appendCapture(
    JSON.stringify({ repository: "https://github.com/Zarby8/FlowAI", messages: [{ content: SENSITIVE_PROMPT }] }),
    { harness: "cursor", event: "prompt-submit", logPath },
  );
  const log = fs.readFileSync(logPath, "utf8");
  fs.rmSync(logPath, { force: true });
  assert.equal(kept.action, "capture.kept");
  assert.equal(dropped.action, "capture.dropped");
  assert.equal(dropped.reason, "cross_repo_transcript");
  assert.equal(dropped.redacted, undefined);
  assert.equal(residue(log), false);
  assert.equal(residue(JSON.stringify(kept.redacted)), false);
});

test("capture demonstration reports no sensitive residue", () => {
  const result = demonstrateCapture();
  assert.equal(result.sensitive_residue, false);
  assert.equal(result.dropped, 1);
});

test("hook script fail-opens and does not forward a foreign transcript", () => {
  const logPath = path.join(os.tmpdir(), `beacon-hook-${process.pid}.jsonl`);
  const upstream = path.join(os.tmpdir(), `beacon-up-${process.pid}.jsonl`);
  const bin = path.join(os.tmpdir(), `beacon-fake-${process.pid}.sh`);
  fs.writeFileSync(bin, "#!/bin/sh\ncat >> \"$BEACON_ENDPOINT_LOG\"\nprintf '%s\\n' '{\"continue\":true}'\n");
  fs.chmodSync(bin, 0o755);
  const foreign = JSON.stringify({
    repository: "https://github.com/Zarby8/forceiq-command-center",
    messages: [{ content: CANARY_SECRET }],
  });
  const child = spawnSync("sh", [path.join(repoRoot, "scripts/beacon/hook.sh"), "--harness", "cursor", "--event", "prompt-submit"], {
    input: foreign,
    encoding: "utf8",
    env: { ...process.env, BEACON_ENDPOINT_LOG: logPath, BEACON_HOOKS_BIN: bin, BEACON_UPSTREAM_LOG: upstream },
  });
  const log = fs.readFileSync(logPath, "utf8");
  assert.equal(child.status, 0);
  assert.match(child.stdout, /\{"continue":true\}/);
  assert.equal(fs.existsSync(upstream), false);
  assert.equal(residue(log), false);
  assert.equal(residue(child.stdout), false);
  fs.rmSync(logPath, { force: true });
  fs.rmSync(bin, { force: true });
});

test("score pins jev-1.13.0 and never applies auto-promote", () => {
  const previous = process.env.BEACON_REVIEW_APPROVE;
  process.env.BEACON_REVIEW_APPROVE = "1";
  const result = scoreEvaluation(safeTrace, jev(), policy);
  process.env.BEACON_REVIEW_APPROVE = previous;
  assert.equal(result.evaluator_model, "jev-1.13.0");
  assert.equal(result.status, "candidate");
  assert.equal(result.candidate.state, "candidate");
  assert.equal(result.promoted, false);
  assert.equal(result.approve_invoked, false);
  assert.equal(result.jev_gate, "auto");
  assert.equal(result.jev_gate_applied, false);
  assert.equal(result.devils_advocate.applied, false);
  assert.ok(result.devils_advocate.auto_promote > 0.9);
});

test("wrong model, low score, and cross-repo traces do not promote", () => {
  const wrong = scoreEvaluation(safeTrace, { model: "jev-latest", answers: jev().answers }, policy);
  assert.equal(wrong.status, "blocked");
  assert.equal(wrong.reason, "model_not_pinned");
  assert.equal(wrong.candidate, null);
  const low = scoreEvaluation(safeTrace, jev({
    task_success: { noul: 0.2 },
    reusable_correction: { noul: 0.2 },
    evidence_supported: { noul: 0.2 },
  }), policy);
  assert.equal(low.status, "below_threshold");
  assert.equal(low.candidate, null);
  const foreign = scoreEvaluation({
    repository: "https://github.com/Zarby8/FlowAI",
    messages: [{ content: SENSITIVE_PROMPT }],
    trace_id: "nope",
  }, jev(), policy);
  assert.equal(foreign.status, "blocked");
  assert.equal(foreign.projection, null);
  assert.equal(residue(JSON.stringify(foreign)), false);
});

test("approve is a separate explicit action", () => {
  const result = scoreEvaluation(safeTrace, jev(), policy);
  assert.throws(() => approveCandidate(result.candidate, { envValue: "1", reason: "short" }));
  assert.throws(() => approveCandidate(result.candidate, { envValue: "", reason: "reviewed by a person" }));
  const approved = approveCandidate(result.candidate, { envValue: "1", reason: "reviewed by a person" });
  assert.equal(approved.state, "approved");
  assert.equal(result.promoted, false);
});

test("product truth requires a scheduled event for a named consumer", () => {
  const result = scoreEvaluation(safeTrace, jev(), policy);
  assert.equal(result.product_truth.status, "PENDING");
  assert.equal(result.product_truth.logs_or_api_alone_sufficient, false);
  assert.throws(() => recordProductTruth(result, { consumer: "Chris" }));
  const verified = recordProductTruth(result, { eventId: "evt_test", consumer: "Chris" });
  assert.equal(verified.product_truth.status, "VERIFIED");
  assert.equal(verified.promoted, false);
});

test("hook configs call the redacting wrapper and do not call Jev", () => {
  const files = [
    ".cursor/hooks.json",
    ".claude/settings.json",
    ".codex/hooks.json",
  ];
  for (const file of files) {
    const body = fs.readFileSync(path.join(repoRoot, file), "utf8");
    JSON.parse(body);
    assert.match(body, /scripts\/beacon\/hook\.sh/);
    assert.doesNotMatch(body, /typesafe|jev-1|beacon-hooks/i);
  }
  const cursor = JSON.parse(fs.readFileSync(path.join(repoRoot, ".cursor/hooks.json"), "utf8"));
  assert.ok(cursor.hooks.beforeSubmitPrompt[0].command.includes("--harness cursor"));
  assert.equal(policy.jev.model, "jev-1.13.0");
  assert.equal(policy.promotion.auto_promote, false);
  assert.equal(policy.jev.hooks_call_jev, false);
});

test("committed proof stays unpromoted when present", () => {
  const proofPath = path.join(repoRoot, "beacon/proof/review.json");
  if (!fs.existsSync(proofPath)) return;
  const proof = JSON.parse(fs.readFileSync(proofPath, "utf8"));
  assert.equal(proof.promoted, false);
  assert.equal(proof.approve_invoked, false);
  assert.equal(proof.evaluator_model, "jev-1.13.0");
  assert.notEqual(proof.candidate && proof.candidate.state, "approved");
  assert.equal(proof.devils_advocate.applied, false);
  assert.equal(proof.capture.sensitive_residue, false);
  assert.equal(proof.upstream_hook.sensitive_residue, false);
  assert.equal(residue(JSON.stringify(proof)), false);
  if (proof.product_truth.status === "VERIFIED") {
    assert.ok(proof.product_truth.event_id);
    assert.equal(proof.product_truth.named_consumer, "Chris");
    assert.equal(proof.product_truth.logs_or_api_alone_sufficient, false);
  }
});

test("upstream beacon-hooks receives only a redacted payload when installed", () => {
  const binary = "/tmp/beacon-src/beacon-hooks";
  if (!fs.existsSync(binary)) return;
  const logPath = path.join(os.tmpdir(), `beacon-upstream-${process.pid}.jsonl`);
  const result = demonstrateUpstreamHook(binary, logPath);
  assert.equal(result.checked, true);
  assert.equal(result.sensitive_residue, false);
});
