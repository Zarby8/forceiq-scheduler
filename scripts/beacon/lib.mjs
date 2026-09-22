import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { residue, SENSITIVE_PROMPT } from "./canaries.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
export const repoRoot = path.resolve(here, "../..");

const REPLACEMENT = "[REDACTED]";
const MAX_TEXT = 1200;
const MAX_RAW = 262144;

const REPO_KEYS = new Set([
  "repository",
  "repo",
  "remote",
  "remoteUrl",
  "remote_url",
  "workspace",
  "cwd",
  "project",
  "source_repo",
  "copied_from",
]);

export function loadPolicy(policyPath = path.join(repoRoot, "beacon/policy.json")) {
  return JSON.parse(fs.readFileSync(policyPath, "utf8"));
}

function truncate(value) {
  if (value.length <= MAX_TEXT) return value;
  return `${value.slice(0, MAX_TEXT - 15)}...[truncated]`;
}

function collectAssignedSecrets(value) {
  const found = [];
  const pattern =
    /(?:api[_-]?key|token|secret|password|authorization|hmac[_-]?secret|private[_-]?key)\s*[:=]\s*["'`]?([^"'`,\s]+)/gi;
  for (const match of value.matchAll(pattern)) {
    if (match[1] && match[1].length >= 12 && match[1] !== REPLACEMENT) found.push(match[1]);
  }
  return found;
}

export function redactText(value) {
  let text = String(value);
  const assigned = collectAssignedSecrets(text);
  text = text.replace(
    /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g,
    REPLACEMENT,
  );
  text = text.replace(/authorization\s*[:=]\s*bearer\s+\S+/gi, `authorization: ${REPLACEMENT}`);
  text = text.replace(
    /(api[_-]?key|token|secret|password|authorization|hmac[_-]?secret|private[_-]?key|calendar[_-]?id|sheet[_-]?id)(\s*[:=]\s*["'`]?)([^\s"'`,]+)/gi,
    (_match, key, separator) => `${key}${separator}${REPLACEMENT}`,
  );
  text = text.replace(/\bbearer\s+[a-z0-9._~+/=-]{8,}/gi, REPLACEMENT);
  text = text.replace(/\bsk-[a-zA-Z0-9]{20,}\b/g, REPLACEMENT);
  text = text.replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, REPLACEMENT);
  text = text.replace(/\b[\w.+-]+@group\.calendar\.google\.com\b/gi, REPLACEMENT);
  text = text.replace(/\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}\b/g, REPLACEMENT);
  text = text.replace(
    /\b(client|player|athlete|parent|guardian)([\s_-]?name)?(\s*[:=]\s*)(?!\[REDACTED\])([^[\n,;\s][^[\n,;]*)/gi,
    (_match, label, name, separator) => `${label}${name || ""}${separator}${REPLACEMENT}`,
  );
  text = text.replace(
    /\b(slot|booking|appointment)(\s*[:=]\s*)(?!\[REDACTED\])([^[\n,;\s][^[\n,;]*)/gi,
    (_match, label, separator) => `${label}${separator}${REPLACEMENT}`,
  );
  text = text
    .split("\n")
    .map((line) => {
      let next = line.replace(
        /\b\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2})?(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?\b/g,
        REPLACEMENT,
      );
      if (/book|slot|session|appointment|available|calendar|working hours/i.test(next)) {
        next = next.replace(/\b\d{4}-\d{2}-\d{2}\b/g, REPLACEMENT);
        next = next.replace(/\b\d{1,2}:\d{2}(?::\d{2})?\s*(?:[AaPp][Mm])?\b/g, REPLACEMENT);
      }
      return next;
    })
    .join("\n");
  for (const secret of assigned) text = text.split(secret).join(REPLACEMENT);
  return truncate(text);
}

export function redactValue(value) {
  if (typeof value === "string") return redactText(value);
  if (Array.isArray(value)) return value.map((item) => redactValue(item));
  if (value && typeof value === "object") {
    const out = {};
    for (const [key, child] of Object.entries(value)) out[key] = redactValue(child);
    return out;
  }
  return value;
}

function repoFields(value, found = []) {
  if (!value || typeof value !== "object") return found;
  for (const [key, child] of Object.entries(value)) {
    if (REPO_KEYS.has(key) && typeof child === "string") found.push(child);
    else if (child && typeof child === "object") repoFields(child, found);
  }
  return found;
}

export function repositoryAllowed(repository, policy = loadPolicy()) {
  if (repository == null || repository === "") return true;
  const value = String(repository).replace(/\/$/, "");
  return policy.project.remotes.some((remote) => remote.replace(/\/$/, "") === value)
    || value === policy.project.id;
}

function isForeignRepoField(value, policy) {
  if (!value) return false;
  if (repositoryAllowed(value, policy)) return false;
  return /github\.com\/|FlowAI|forceiq-command-center|forceiq-ghost|forceiq-brain/i.test(value);
}

function isRawTranscript(payload) {
  if (!payload || typeof payload !== "object") return false;
  if (payload.transcript != null) return true;
  if (payload.kind === "transcript" || payload.type === "transcript") return true;
  if (Array.isArray(payload.messages) && payload.messages.length > 0 && !payload.hook_event_name && !payload.conversation_id) {
    return true;
  }
  return false;
}

export function captureDecision(raw, policy = loadPolicy()) {
  if (raw.length > (policy.capture.max_raw_bytes || MAX_RAW)) {
    return { action: "capture.dropped", reason: "oversize" };
  }
  let payload = null;
  try {
    payload = JSON.parse(raw);
  } catch {
    payload = null;
  }
  if (payload && typeof payload === "object") {
    if (isRawTranscript(payload) || repoFields(payload).some((field) => isForeignRepoField(field, policy))) {
      return { action: "capture.dropped", reason: "cross_repo_transcript" };
    }
    return { action: "capture.kept", redacted: redactValue(payload) };
  }
  return { action: "capture.kept", redacted: { prompt: redactText(raw) } };
}

export function captureRecord(raw, { harness, event, policy = loadPolicy() } = {}) {
  const decision = captureDecision(raw, policy);
  const record = {
    schema_version: "forceiq.beacon.capture.v1",
    project_id: policy.project.id,
    harness: harness || "unknown",
    event: event || "unknown",
    action: decision.action,
    reason: decision.reason || null,
    bytes: Buffer.byteLength(raw),
    sha256: createHash("sha256").update(raw).digest("hex"),
    captured_at: new Date().toISOString(),
  };
  if (decision.action === "capture.kept") record.redacted = decision.redacted;
  return record;
}

export function defaultLogPath() {
  return process.env.BEACON_ENDPOINT_LOG || path.join(repoRoot, ".beacon/endpoint/logs/runtime.jsonl");
}

export function appendCapture(raw, options) {
  const record = captureRecord(raw, options);
  const logPath = options.logPath || defaultLogPath();
  fs.mkdirSync(path.dirname(logPath), { recursive: true });
  fs.appendFileSync(logPath, `${JSON.stringify(record)}\n`);
  return record;
}

function noulOf(answer) {
  if (!answer || typeof answer !== "object") return null;
  const value = answer.noul ?? answer.probability ?? answer.score;
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return Math.min(1, Math.max(0, value));
}

function answersOf(jev) {
  if (jev && jev.answers && typeof jev.answers === "object") return jev.answers;
  return {};
}

export function projectTrace(trace, policy = loadPolicy()) {
  const events = Array.isArray(trace.events) ? trace.events.slice(0, policy.upstream.max_projection_events) : [];
  return {
    synthetic: Boolean(trace.synthetic),
    trace_id: trace.trace_id,
    title: redactText(trace.title || ""),
    harness: trace.harness || "",
    repository: trace.repository || policy.project.remotes[0],
    events: events.map((event) => ({
      number: event.number,
      type: event.type,
      action: event.action,
      summary: redactText(event.summary || ""),
      content: redactText(event.content || ""),
    })),
  };
}

function blocked(reason, extra = {}) {
  return {
    schema_version: "forceiq.beacon.review.v1",
    status: "blocked",
    reason,
    promoted: false,
    approve_invoked: false,
    candidate: null,
    ...extra,
  };
}

export function scoreEvaluation(trace, jev, policy = loadPolicy()) {
  if (!repositoryAllowed(trace.repository, policy) || trace.transcript != null || Array.isArray(trace.messages)) {
    return blocked("cross_repo", { projection: null });
  }
  const original = JSON.stringify(trace);
  const projection = projectTrace(trace, policy);
  if (residue(JSON.stringify(projection)) || redactText(original) !== redactText(redactText(original))) {
    return blocked("redaction_failed", { projection: null });
  }
  if (redactText(original) !== original && residue(original)) {
    return blocked("redaction_hold", {
      projection,
      devils_advocate: { applied: false, redaction_holds: 0, reason: "projection changed under redaction" },
    });
  }
  const model = typeof jev?.model === "string" ? jev.model : "";
  if (model !== policy.jev.model) {
    return blocked("model_not_pinned", { evaluator_model: model || null, required_model: policy.jev.model, projection });
  }
  const answers = answersOf(jev);
  const questions = policy.rubric.map((question) => ({
    id: question.id,
    prompt: question.prompt,
    probability: noulOf(answers[question.id]),
  }));
  if (questions.some((question) => question.probability == null)) {
    return blocked("rubric_incomplete", { evaluator_model: model, projection, questions });
  }
  const advocate = {};
  for (const question of policy.devils_advocate) advocate[question.id] = noulOf(answers[question.id]);
  const score = questions.reduce((sum, question) => sum + question.probability, 0) / questions.length;
  const redactionHolds = advocate.redaction_holds;
  const base = {
    schema_version: "forceiq.beacon.review.v1",
    project_id: policy.project.id,
    evaluator_model: model,
    rubric_version: policy.upstream.rubric_version,
    score,
    questions,
    projection,
    jev_gate: jev.gate || null,
    jev_gate_applied: false,
    devils_advocate: {
      ...advocate,
      applied: false,
    },
    promoted: false,
    approve_invoked: false,
    candidate: null,
    product_truth: {
      status: "PENDING",
      named_consumer: policy.product_truth.named_consumer,
      logs_or_api_alone_sufficient: false,
    },
  };
  if (redactionHolds != null && redactionHolds < policy.redaction.redaction_holds_minimum) {
    return { ...base, status: "redaction_hold", reason: "devils_advocate_redaction" };
  }
  if (score < policy.upstream.candidate_score_threshold) {
    return { ...base, status: "below_threshold", reason: "score_below_threshold" };
  }
  return {
    ...base,
    status: "candidate",
    reason: "awaiting_human_review",
    candidate: {
      id: `cand_${createHash("sha256").update(`${policy.project.id}\n${trace.trace_id}`).digest("hex").slice(0, 16)}`,
      state: "candidate",
      project_id: policy.project.id,
      trace_id: trace.trace_id,
      title: projection.title,
      score,
    },
  };
}

export function approveCandidate(candidate, { envValue, reason } = {}) {
  if (envValue !== "1") throw new Error("approval refused: BEACON_REVIEW_APPROVE is not 1");
  if (!reason || reason.trim().length < 8) throw new Error("approval refused: reason is required");
  if (!candidate || candidate.state !== "candidate") throw new Error("approval refused: not a review candidate");
  return {
    ...candidate,
    state: "approved",
    review_reason: reason.trim(),
    promoted: true,
  };
}

export function recordProductTruth(proof, { eventId, consumer, htmlLink, start, end } = {}) {
  if (!eventId || !consumer) throw new Error("product truth requires a scheduled event and a named consumer");
  return {
    ...proof,
    promoted: false,
    approve_invoked: false,
    product_truth: {
      status: "VERIFIED",
      named_consumer: consumer,
      event_id: eventId,
      html_link: htmlLink || null,
      start: start || null,
      end: end || null,
      logs_or_api_alone_sufficient: false,
    },
  };
}

export function demonstrateCapture(logPath = path.join(os.tmpdir(), `beacon-demo-${process.pid}.jsonl`)) {
  fs.rmSync(logPath, { force: true });
  const kept = appendCapture(
    JSON.stringify({ conversation_id: "demo", prompt: SENSITIVE_PROMPT }),
    { harness: "cursor", event: "prompt-submit", logPath },
  );
  const dropped = appendCapture(
    JSON.stringify({
      repository: "https://github.com/Zarby8/FlowAI",
      messages: [{ role: "user", content: SENSITIVE_PROMPT }],
    }),
    { harness: "cursor", event: "prompt-submit", logPath },
  );
  const log = fs.readFileSync(logPath, "utf8");
  fs.rmSync(logPath, { force: true });
  const sensitiveResidue = residue(log);
  if (sensitiveResidue || kept.action !== "capture.kept" || dropped.action !== "capture.dropped") {
    throw new Error("capture demonstration failed closed");
  }
  return {
    kept: 1,
    dropped: 1,
    drop_reason: dropped.reason,
    sensitive_residue: false,
  };
}

export function demonstrateUpstreamHook(binary, logPath) {
  if (!binary || !fs.existsSync(binary)) return { checked: false, sensitive_residue: false };
  fs.rmSync(logPath, { force: true });
  fs.mkdirSync(path.dirname(logPath), { recursive: true });
  const redacted = redactValue({ conversation_id: "upstream-demo", prompt: SENSITIVE_PROMPT });
  const child = spawnSync(binary, ["--platform", "cursor", "prompt-submit"], {
    input: JSON.stringify(redacted),
    encoding: "utf8",
    env: {
      ...process.env,
      BEACON_ENDPOINT_MODE: "1",
      BEACON_ORIGIN: "cloud",
      BEACON_RUN_PROVIDER: "cursor_cloud",
      BEACON_RUN_EPHEMERAL: "true",
      BEACON_ENDPOINT_LOG: logPath,
    },
  });
  const log = fs.existsSync(logPath) ? fs.readFileSync(logPath, "utf8") : "";
  fs.rmSync(logPath, { force: true });
  const sensitiveResidue = residue(log) || residue(child.stdout || "") || residue(child.stderr || "");
  if (child.status !== 0 || sensitiveResidue || !log.includes("prompt.submitted")) {
    throw new Error("upstream hook demonstration failed closed");
  }
  return { checked: true, exit_code: child.status, sensitive_residue: false };
}
