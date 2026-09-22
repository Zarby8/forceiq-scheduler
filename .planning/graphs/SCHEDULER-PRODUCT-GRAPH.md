# Scheduler product graph

Atlas opened 2026-09-22. `.planning/graphs/` was absent before this change.

| id | Kind | Reach |
| --- | --- | --- |
| macos.app | product | Mac app sends a signed booking link. |
| booking.page | product | Public page selects a slot and submits. |
| booking.api | product | Apps Script checks the signature, writes the calendar, logs the sheet. |
| beacon.memory | engineering | Reviewed, repo-scoped agent memory. Capture redacts. Scoring requires live `jev-1.13.0`. Promotion stays in review. |

`beacon.memory` is not on the booking path. Do not add a second booking path for it.
