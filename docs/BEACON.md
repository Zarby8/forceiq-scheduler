# Beacon memory in ForceIQ Scheduler

Repo-scoped cross-harness memory for `Zarby8/forceiq-scheduler`, adapted from [Asymptote-Labs/agent-beacon](https://github.com/Asymptote-Labs/agent-beacon) v1.3.18 (`2d33d6ae`). Policy lives in `beacon/policy.json`.

## What is hooked

Cursor, Claude Code, and Codex project hooks call `scripts/beacon/hook.sh`. The hook:

1. Redacts client identities, appointment times, and secrets.
2. Drops a raw transcript whose repository is not this one, without storing the body.
3. Appends the redacted record to gitignored `.beacon/endpoint/logs/runtime.jsonl`.
4. Forwards only that redacted payload to `beacon-hooks` when `BEACON_HOOKS_BIN` or `/tmp/beacon/bin/beacon-hooks` exists.

The hook always exits successfully and answers `{"continue":true}` if the upstream binary is absent. It does not call Jev.

Upstream `beacon-hooks` v1.3.18 redacts labeled secrets. A labeled client name and an ISO appointment timestamp still remained in `prompt.text` when this was checked. That is why this repository redacts before the upstream hook runs. Do not replace `hook.sh` with `beacon cloud cursor print-hooks` output: that command wires `beacon-hooks` to the raw payload.

## Score and review

Scoring is a separate command. It accepts a live Jev response only when `model` is exactly `jev-1.13.0`. `jev-latest` is blocked.

```bash
node scripts/beacon/review.mjs score \
  --trace beacon/fixtures/safe-trace.json \
  --jev beacon/proof/jev-response.json \
  --out beacon/proof/review.json
```

Beacon's three rubric questions are averaged. A score of at least 0.60 can create a candidate whose state is `candidate`. Devil's Advocate answers are stored and not applied:

- `auto_promote` never approves the candidate, including when Jev's gate is `auto`.
- `redaction_holds` below 0.80 prevents a candidate.
- `logs_alone_sufficient` does not mark the change done.

Approval is explicit and unused by the proof path:

```bash
BEACON_REVIEW_APPROVE=1 node scripts/beacon/review.mjs approve \
  --candidate candidate.json \
  --reason "reviewed by a person"
```

## Product truth

A test log or an API body is not done. The named consumer is Chris. His connected calendar is `coachzarby@gmail.com`, and `chris@forcehockeyiq.com` is an attendee. Record the event with `review.mjs product-truth` only after it exists on that calendar.

The live `jev-1.13.0` score for `beacon/fixtures/safe-trace.json` was 0.57, under the 0.60 candidate line, so nothing was promoted. Devil's Advocate scored auto-promote 0.04 and logs-alone 0.08. The review hold is calendar event `rmb750jk89edh2ojgam7e34em0`, 17:30–17:45 America/Detroit on 2026-09-22. This environment's browser was signed out of Google Calendar, so that page was the public marketing site rather than Chris's agenda.

## Tests

```bash
node --test scripts/beacon/beacon.test.mjs
```
