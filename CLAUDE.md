# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a three-part scheduling system for ForceIQ hockey training:

### Components
1. **macOS SwiftUI App** (`app-macos/`) - Client management and iMessage sending with unique booking links
2. **Google Apps Script Backend** (`apps-script/Code.gs`) - Availability API, calendar booking, and sheet logging
3. **Static Web Booking Page** (`web/`) - Branded booking interface served at schedule.forcehockeyiq.com

### Data Flow
- Swift app generates HMAC-signed per-client links and sends via Messages
- Web page calls Apps Script to fetch availability and submit bookings
- Apps Script verifies HMAC signatures, books to Google Calendar, and logs to Google Sheets
- Email confirmations sent to client and owners (chris@forcehockeyiq.com, shaneb@forcehockeyiq.com)

## Key Configuration Files

### app-macos/Config.swift
- `WEB_BASE`: Public booking page URL
- `GAS_BASE`: Apps Script deployment URL (ends with /exec)
- `HMAC_SECRET`: Shared secret for link signing
- ForceIQ brand colors defined

### apps-script/Code.gs CONFIG object
- `CALENDAR_ID`: Dedicated Google Calendar for bookings
- `SHEET_ID`: Google Sheet for logging
- `WORKING_HOURS`: Weekly availability windows by weekday
- `HMAC_SECRET`: Must match Swift app
- `OWNER_EMAILS`: Notification recipients

### web/app.js
- `GAS_BASE`: Must match Apps Script deployment URL

## Development Commands

### Swift macOS App
- Open in Xcode: Create new macOS App project, add files from `app-macos/`
- Build: Xcode → Product → Build
- Archive for distribution: Product → Archive
- **Required Info.plist key**: `NSAppleEventsUsageDescription`

### Google Apps Script
- Deploy: script.google.com → New deployment → Web app → Execute as: You → Access: Anyone with link
- Test: Use Apps Script editor's built-in testing

### Web Frontend
- No build process - static files
- Host contents of `web/` at schedule.forcehockeyiq.com
- Update `GAS_BASE` in `app.js` to match deployed Apps Script URL

## Security Notes

- Links are HMAC-signed with timestamp validation in Apps Script
- All three components must share the same `HMAC_SECRET`
- Apps Script verifies signatures and rejects expired links
- Consider rotating `HMAC_SECRET` periodically (update all three components)

## Distribution

### Developer ID Signing (for Shane)
1. Set Team and unique Bundle Identifier in Xcode
2. Product → Archive → Distribute App → Developer ID → Upload for notarization
3. Export notarized .app or .dmg

### Ad-hoc Distribution
- Product → Archive → Distribute → Copy App
- Recipient may need Control-click → Open to bypass Gatekeeper

## Testing End-to-End

1. Add test client in macOS app with your handle/email
2. Send message → receive iMessage with link
3. Open link → select slot → submit
4. Verify: Calendar event created, Sheet row added, emails sent