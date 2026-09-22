# Scheduler feature map

Atlas opened 2026-09-22. This repository had no feature map before the Beacon change.

| id | Who reaches it | Where | Notes |
| --- | --- | --- | --- |
| macos.app | Coach on a Mac | `ForceIQScheduler/`, `ForceIQSchedulerPackage/` | Clients and booking links. |
| booking.page | Person with a link | `index.html`, `app.js`, `styles.css` | Week view and booking form. Files are at the repo root. |
| booking.api | The booking page | `apps-script/Code.gs` | Availability, calendar write, sheet log. |
| beacon.memory | Engineer | `docs/BEACON.md` | Cross-harness memory. Not a booking control. No auto-promote. |

Coach-facing booking does not read Beacon memory. Beacon memory does not create a client booking.
