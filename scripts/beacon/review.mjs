#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import {
  approveCandidate,
  demonstrateCapture,
  demonstrateUpstreamHook,
  loadPolicy,
  recordProductTruth,
  repoRoot,
  scoreEvaluation,
} from "./lib.mjs";

function option(name) {
  const index = process.argv.indexOf(name);
  if (index === -1) return "";
  return process.argv[index + 1] || "";
}

const command = process.argv[2];
const policy = loadPolicy();

if (command === "score") {
  const trace = JSON.parse(fs.readFileSync(option("--trace"), "utf8"));
  const jev = JSON.parse(fs.readFileSync(option("--jev"), "utf8"));
  const result = scoreEvaluation(trace, jev, policy);
  result.capture = demonstrateCapture();
  result.upstream_hook = demonstrateUpstreamHook(
    process.env.BEACON_HOOKS_BIN || "",
    path.join(repoRoot, ".beacon", "upstream-demo.jsonl"),
  );
  result.promoted = false;
  result.approve_invoked = false;
  const out = option("--out");
  const body = `${JSON.stringify(result, null, 2)}\n`;
  if (out) fs.writeFileSync(out, body);
  else process.stdout.write(body);
  process.exit(result.status === "blocked" ? 2 : 0);
}

if (command === "approve") {
  const candidate = JSON.parse(fs.readFileSync(option("--candidate"), "utf8"));
  const approved = approveCandidate(candidate, {
    envValue: process.env[policy.promotion.approve_env],
    reason: option("--reason"),
  });
  process.stdout.write(`${JSON.stringify(approved, null, 2)}\n`);
  process.exit(0);
}

if (command === "product-truth") {
  const proofPath = option("--proof");
  const proof = JSON.parse(fs.readFileSync(proofPath, "utf8"));
  const next = recordProductTruth(proof, {
    eventId: option("--event-id"),
    consumer: option("--consumer"),
    htmlLink: option("--html-link"),
    start: option("--start"),
    end: option("--end"),
  });
  fs.writeFileSync(option("--out") || proofPath, `${JSON.stringify(next, null, 2)}\n`);
  process.exit(0);
}

process.stderr.write("usage: review.mjs score|approve|product-truth\n");
process.exit(1);
