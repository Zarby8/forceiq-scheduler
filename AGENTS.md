# Scheduler agent notes

## ATLAS FIRST

Before a product or engineering edit, open:

- `.planning/graphs/SCHEDULER-ENG-LOOP.md`
- `.planning/graphs/SCHEDULER-PRODUCT-GRAPH.md`
- `docs/FEATURE-MAP.md`
- `.planning/graphs/SCHEDULER-WORKFLOWS.json`

These files did not exist before the Beacon integration. If a change touches a surface that is missing, update the atlas in the same change. Do not merge this atlas with FLOW or Command graphs.

The Beacon surface is `beacon.memory`. It is engineering-only.

## Beacon memory

- Capture hooks never call Jev.
- The evaluator pin is `jev-1.13.0`. Any other model is blocked.
- Do not auto-promote. Approval needs `BEACON_REVIEW_APPROVE=1` and a written reason. The proof path does not approve.
- Do not store raw transcripts from other repositories.
- Redact client identities, appointment times, and secrets before a trace is kept, forwarded, or scored.
- Product truth is a scheduled outcome Chris can see. A test log or an API body is not enough.

Operator detail: `docs/BEACON.md`.
