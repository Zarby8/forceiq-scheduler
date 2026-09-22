# Scheduler engineering loop

Node for this change: `beacon.memory`.

1. Open this file, `SCHEDULER-PRODUCT-GRAPH.md`, `docs/FEATURE-MAP.md`, and `SCHEDULER-WORKFLOWS.json`.
2. Edit the Beacon hook, policy, or review command.
3. Run `node --test scripts/beacon/beacon.test.mjs`.
4. Score a redacted synthetic trace with a live `jev-1.13.0` response. Leave the candidate unapproved.
5. Product truth is a calendar event Chris can see. Logs and the Jev response are not that event.
6. Open the pull request. Merge only when the check is green and the scheduled outcome exists.
