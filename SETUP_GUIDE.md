# ForceIQ Scheduler v2.0 - Complete Setup Guide

This guide walks you through setting up the complete scheduling system from scratch.

---

## Overview

**Three Components:**
1. **Vercel API** (Backend for booking) → Deployed to Vercel
2. **Web Booking Page** (Client-facing) → Static hosting on Vercel
3. **macOS App** (Coach dashboard) → Run locally on Mac

---

## Part 1: Deploy Backend to Vercel

### Step 1: Create Google Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project: "ForceIQ Scheduler"
3. Enable APIs:
   - Google Calendar API
4. Create Service Account:
   - IAM & Admin → Service Accounts → Create
   - Name: "forceiq-scheduler-bot"
   - Grant role: "Project → Editor"
   - Click "Create Key" → JSON
   - Download and save the JSON file

5. Extract credentials from JSON:
   ```json
   {
     "client_email": "forceiq-scheduler-bot@....iam.gserviceaccount.com",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   }
   ```

### Step 2: Create Google Calendars

1. Open [Google Calendar](https://calendar.google.com)
2. Create two calendars:
   - "Chris - ForceIQ Training"
   - "Shane - ForceIQ Training"

3. For each calendar:
   - Click ⚙️ Settings → Select calendar
   - Scroll to "Share with specific people"
   - Add: `forceiq-scheduler-bot@....iam.gserviceaccount.com`
   - Permission: "Make changes to events"
   - Save

4. Get Calendar IDs:
   - Settings → Select calendar → Integrate calendar
   - Copy "Calendar ID" (looks like: `abc123@group.calendar.google.com`)

### Step 3: Deploy to Vercel

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel**
   ```bash
   vercel login
   ```

3. **Deploy**
   ```bash
   cd /Users/christopherzarb/forceiq-scheduler
   vercel --prod
   ```

4. **Set Environment Variables**

   In Vercel Dashboard → Project → Settings → Environment Variables:

   ```
   GOOGLE_SERVICE_ACCOUNT_EMAIL=forceiq-scheduler-bot@....iam.gserviceaccount.com
   GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n
   COACH_1_ID=coach1
   COACH_1_NAME=Chris
   COACH_1_EMAIL=chris@forcehockeyiq.com
   COACH_1_CALENDAR_ID=abc123@group.calendar.google.com
   COACH_1_BIO=Lead Coach & Analytics Expert
   COACH_1_COLOR=#F4C430
   COACH_2_ID=coach2
   COACH_2_NAME=Shane
   COACH_2_EMAIL=shaneb@forcehockeyiq.com
   COACH_2_CALENDAR_ID=def456@group.calendar.google.com
   COACH_2_BIO=Performance Coach
   COACH_2_COLOR=#4FFF4F
   ```

5. **Redeploy** after adding env vars:
   ```bash
   vercel --prod
   ```

6. **Test API**
   ```bash
   curl https://schedule.forcehockeyiq.com/api/coaches
   ```

   Should return:
   ```json
   {
     "coaches": [
       {"id": "coach1", "name": "Chris", ...},
       {"id": "coach2", "name": "Shane", ...}
     ]
   }
   ```

✅ **Backend is now live!**

---

## Part 2: Verify Web Booking Page

The booking page is deployed automatically with Vercel.

### Test Booking Flow

1. **Open booking page**
   ```
   https://schedule.forcehockeyiq.com
   ```

2. **Should see:**
   - Two coach cards (Chris and Shane)
   - Click a coach → availability loads
   - Select time slot → booking form appears

3. **Test booking:**
   - Fill in client details
   - Submit
   - Check Google Calendar → event should appear

✅ **Booking page is live and working!**

---

## Part 3: Build macOS App

### Step 1: Install Xcode

1. Download Xcode from Mac App Store
2. Open Xcode → Agree to license
3. Install Command Line Tools:
   ```bash
   xcode-select --install
   ```

### Step 2: Create Xcode Project

1. **Launch Xcode**
2. File → New → Project
3. **Template:** macOS → App
4. **Settings:**
   - Product Name: `ForceIQ Scheduler`
   - Team: Your Apple ID (or None for local use)
   - Organization Identifier: `com.forcehockeyiq`
   - Bundle Identifier: `com.forcehockeyiq.scheduler`
   - Interface: **SwiftUI**
   - Language: **Swift**
5. **Save in:** `/Users/christopherzarb/forceiq-scheduler/ForceIQSchedulerApp`

### Step 3: Add Source Files

1. **In Xcode Project Navigator:**
   - Delete default `ContentView.swift` and `ForceIQSchedulerApp.swift`

2. **Add all source files:**
   - Right-click project name → "Add Files to 'ForceIQ Scheduler'..."
   - Navigate to: `ForceIQSchedulerApp/Sources/`
   - Select **ALL** `.swift` files:
     - AppModel.swift
     - ClientsView.swift
     - ContentView.swift
     - DashboardView.swift
     - AvailabilityView.swift
     - SettingsView.swift
     - ForceIQSchedulerApp.swift
     - GoogleAuthService.swift
     - IMessageService.swift
     - Models.swift
     - StorageManager.swift
     - SundayScheduler.swift
     - Theme.swift
   - ✅ **Check:** "Copy items if needed"
   - ✅ **Check:** "Create groups"
   - Click "Add"

### Step 4: Configure Info.plist

1. **Replace Info.plist:**
   - In Xcode, select `Info.plist` in project
   - Delete it
   - Drag `ForceIQSchedulerApp/Info.plist` into project
   - ✅ Check: "Copy items if needed"

2. **Verify iMessage permission:**
   - Open Info.plist
   - Should contain: `NSAppleEventsUsageDescription`
   - Value: "ForceIQ Scheduler needs access to send iMessages..."

### Step 5: Build Settings

1. **Select project** in Navigator (top item)
2. **Select target:** "ForceIQ Scheduler"
3. **General tab:**
   - Minimum Deployments → macOS: `14.0`
4. **Signing & Capabilities:**
   - **Team:** None (for local use) or your Apple ID
   - Disable "App Sandbox" (required for iMessage access)

### Step 6: Build and Run

1. **Build:** Product → Build (⌘B)
   - Fix any errors (should be none if all files added correctly)

2. **Run:** Product → Run (⌘R)
   - App should launch with ForceIQ branding
   - Black background, HUD-style interface

3. **Grant Permissions:**
   - First launch: System will prompt for Automation access
   - Allow "ForceIQ Scheduler" to control "Messages"

✅ **App is now running!**

---

## Part 4: Configure macOS App

### Initial Setup

1. **Open Settings Tab**
   - Click "Settings" in sidebar

2. **Set Booking Page URL**
   - Enter: `https://schedule.forcehockeyiq.com`
   - This is where clients will book

3. **Configure Sunday Auto-Send**
   - Toggle ON
   - Set send time: `9:00 AM` (or your preferred time)
   - Message template (default is good):
     ```
     Hi {name}! Ready to level up your game? 🏒

     Book your 1-on-1 session: {link}

     - ForceIQ Team
     ```

4. **Test iMessage**
   - Click "Test iMessage Connection"
   - Sends test message to verify Messages.app access
   - Check your iMessages for test message

### Add Clients

1. **Go to Clients Tab**
2. **Click "Add Client"**
3. **Enter details:**
   - Name: `John Doe`
   - Email: `john@example.com`
   - Phone: `+1234567890` (must be iMessage-capable)
   - Notes: Optional
4. **Save**

Repeat for all your clients.

### Set Availability

1. **Go to Availability Tab**
2. **Select Coach:** Chris or Shane (toggle at top)
3. **For each weekday:**
   - Click weekday to expand
   - Click "Add Time Block"
   - Enter start/end times (e.g., "10:00" to "14:00")
   - Add multiple blocks if needed
4. **Changes save automatically**

Example for Chris:
- Monday: 10:00-14:00, 17:00-20:00
- Tuesday: 10:00-14:00
- Thursday: 17:00-20:00
- Saturday: 09:00-12:00

---

## Part 5: Test End-to-End

### Manual Send Test

1. **Dashboard Tab**
2. **Click "Send Now"** on Sunday Scheduler card
3. **Check iMessages:**
   - All clients should receive messages
   - Each message has unique booking link
4. **Click a booking link:**
   - Opens web page
   - Shows coach selection
   - Shows availability (only times you set)
5. **Complete a booking:**
   - Select coach
   - Pick time slot
   - Fill details
   - Submit
6. **Verify in Google Calendar:**
   - Open coach's calendar
   - Should see new event

### Automated Sunday Send Test

1. **Wait for next Sunday at 9:00 AM** (or your configured time)
2. **App must be running** (see Launch Agent setup below)
3. **Messages send automatically**
4. **Check logs:**
   ```bash
   log stream --predicate 'subsystem contains "ForceIQ"' --level debug
   ```
   Should see:
   ```
   📤 Starting Sunday message send...
   ✅ Sent to John Doe
   ✅ Sent to Jane Smith
   ✅ Sunday message send complete
   ```

---

## Part 6: Keep App Running (Launch Agent)

To ensure Sunday messages send even if app is quit:

### Create Launch Agent

1. **Create plist file:**
   ```bash
   nano ~/Library/LaunchAgents/com.forcehockeyiq.scheduler.plist
   ```

2. **Paste:**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.forcehockeyiq.scheduler</string>
       <key>ProgramArguments</key>
       <array>
           <string>/Applications/ForceIQ Scheduler.app/Contents/MacOS/ForceIQ Scheduler</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <true/>
   </dict>
   </plist>
   ```

3. **Save:** Ctrl+X, Y, Enter

4. **Load agent:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.forcehockeyiq.scheduler.plist
   ```

5. **Verify:**
   ```bash
   launchctl list | grep forceiq
   ```

✅ **App now auto-starts on login and stays running!**

---

## Troubleshooting

### iMessage Not Sending

**Symptom:** Messages don't send, no error

**Fix:**
1. System Settings → Privacy & Security → Automation
2. Find "ForceIQ Scheduler"
3. Enable checkbox for "Messages"
4. Restart app

### Sunday Auto-Send Not Working

**Symptom:** Sunday comes, no messages sent

**Check:**
1. Is "Sunday Auto-Send" toggled ON in Settings?
2. Is app actually running? (Check Activity Monitor)
3. Check Console.app logs (filter: "ForceIQ")
4. Verify send time is correct

**Fix:**
- Set up Launch Agent (see Part 6)
- Don't quit app, let it run in background

### Booking Page Shows No Availability

**Symptom:** Web page says "No slots available"

**Check:**
1. Are availability hours set in macOS app?
2. Did you set availability for the CORRECT coach?
3. Are you looking at future dates (not past)?

**Fix:**
- Open macOS app → Availability tab
- Select coach (Chris or Shane)
- Add time blocks for each weekday
- Refresh web page

### API Not Working

**Symptom:** Web page shows "Failed to load coaches"

**Check:**
1. Is Vercel deployment successful?
2. Are environment variables set correctly?
3. Test API directly:
   ```bash
   curl https://schedule.forcehockeyiq.com/api/coaches
   ```

**Fix:**
- Redeploy: `vercel --prod`
- Check Vercel logs: `vercel logs`
- Verify Google service account has calendar access

### Bookings Not Appearing in Calendar

**Symptom:** Booking confirms but no event in Google Calendar

**Check:**
1. Is service account email added to calendar with "Make changes to events" permission?
2. Is correct Calendar ID in Vercel environment variables?
3. Check Vercel function logs

**Fix:**
- Google Calendar → Settings → Share calendar → Add service account
- Verify Calendar ID matches environment variable
- Test booking with Vercel logs open

---

## Daily Workflow

### For Chris (Running the App)

**Monday Morning:**
1. Check Dashboard → See this week's bookings
2. If needed: Add/edit client in Clients tab
3. If schedule changes: Update Availability tab

**Every Sunday 9:00 AM:**
- App automatically sends iMessages to all clients
- No action needed!

**After Client Books:**
- Booking appears in your Google Calendar
- Get email notification (if configured)
- Review in Dashboard next time you open app

### For Shane (Using the System)

**One-Time Setup:**
1. Chris builds app and sends you .app file
2. Copy to Applications folder
3. Double-click to launch
4. Grant iMessage permission when prompted

**Daily Use:**
- Same as Chris above
- See your own bookings in Dashboard
- Clients book with either coach

---

## Maintenance

### Adding a New Client

1. Clients tab → Add Client
2. Done! Next Sunday they'll get message

### Changing Availability

1. Availability tab
2. Select your coach
3. Modify time blocks
4. Changes reflect immediately on booking page

### Changing Message Template

1. Settings tab
2. Edit "Message Template"
3. Use `{name}` and `{link}` placeholders
4. Changes apply to next Sunday send

### Backup Clients

1. Settings tab → Data Management
2. Click "Export Clients"
3. Save JSON file to safe location
4. To restore: Click "Import Clients"

---

## Summary Checklist

- [ ] Part 1: Vercel API deployed and tested
- [ ] Part 2: Web booking page works end-to-end
- [ ] Part 3: macOS app built in Xcode
- [ ] Part 4: App configured (URL, Sunday send, clients, availability)
- [ ] Part 5: Tested manual send + booking flow
- [ ] Part 6: Launch Agent configured for auto-start
- [ ] Troubleshooting: iMessage permission granted
- [ ] Backup: Clients exported to JSON

---

## Need Help?

**Email:** chris@forcehockeyiq.com

**Logs:**
```bash
# App logs
log stream --predicate 'subsystem contains "ForceIQ"' --level debug

# Vercel logs
vercel logs --follow
```

---

**ForceIQ Scheduler v2.0** - Simple. Automated. Elite.
