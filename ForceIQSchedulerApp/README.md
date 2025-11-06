# ForceIQ Scheduler macOS App v2.0

A focused, elite-level scheduling app for ForceIQ coaches to manage client bookings with automated iMessage reminders.

## Features

### ⚡ Core Functionality
- **Client Management**: Add, edit, delete, and search clients
- **Sunday Auto-Send**: Automated iMessage scheduling every Sunday
- **Availability Management**: Set weekly working hours per coach
- **Dashboard**: View upcoming bookings from both coaches
- **Settings**: Configure message templates and URLs

### 🎨 ForceIQ Brand Design
- Elite HUD-inspired interface
- Black/charcoal foundation with electric accenting
- Highlight Yellow (#F4C430) primary accent
- Electric Green (#4FFF4F) for CTAs
- Force Red (#C41E3A) for borders and alerts

## Building the App

### Prerequisites
- macOS 14.0 or later
- Xcode 15 or later
- Apple Developer account (for distribution)

### Option 1: Build with Xcode (Recommended)

1. **Create Xcode Project**
   ```bash
   cd ForceIQSchedulerApp
   ```

2. **In Xcode:**
   - File → New → Project
   - Choose: macOS → App
   - Product Name: `ForceIQ Scheduler`
   - Bundle Identifier: `com.forcehockeyiq.scheduler`
   - Interface: SwiftUI
   - Language: Swift
   - Save in `ForceIQSchedulerApp/` directory

3. **Add Source Files**
   - Delete the default `ContentView.swift` and `ForceIQSchedulerApp.swift`
   - In Xcode, right-click project → Add Files to "ForceIQ Scheduler"
   - Select all `.swift` files from `Sources/` folder
   - ✅ Copy items if needed
   - ✅ Create groups

4. **Configure Info.plist**
   - Replace default Info.plist with `Info.plist` from this directory
   - **Critical**: Includes `NSAppleEventsUsageDescription` for iMessage access

5. **Set Minimum Deployment Target**
   - Select project in navigator
   - Build Settings → Deployment → macOS Deployment Target: `14.0`

6. **Build**
   - Product → Build (⌘B)
   - Product → Run (⌘R) to test

### Option 2: Build with Swift Package Manager

```bash
cd ForceIQSchedulerApp
swift build -c release
```

The app will be in `.build/release/ForceIQ Scheduler.app`

## Running the App

### First Launch

1. **Grant Permissions**
   - System will prompt for iMessage access
   - System Settings → Privacy & Security → Automation
   - Enable "ForceIQ Scheduler" → Messages

2. **Initial Setup**
   - Go to Settings tab
   - Set booking page URL (default: https://schedule.forcehockeyiq.com)
   - Configure Sunday auto-send time (default: 9:00 AM)
   - Customize message template

3. **Add Clients**
   - Go to Clients tab
   - Click "Add Client"
   - Enter: Name, Email, Phone (iMessage handle)
   - Save

4. **Set Availability**
   - Go to Availability tab
   - Select coach (Chris or Shane)
   - Expand each weekday
   - Add time blocks (e.g., "10:00" to "14:00")
   - Changes save automatically

5. **Enable Sunday Auto-Send**
   - Go to Settings tab
   - Toggle "Sunday Auto-Send" ON
   - Messages will automatically send every Sunday at configured time

## Sunday Auto-Send Flow

```
SUNDAY at 9:00 AM:
├─ App checks: Is Sunday scheduler enabled?
├─ Loops through all clients
├─ For each client:
│  ├─ Generate booking link with client ID
│  ├─ Replace {name} and {link} in message template
│  ├─ Send iMessage to client's phone number
│  └─ Update lastMessageSent timestamp
└─ Update lastSentDate in config
```

**Message Template Variables:**
- `{name}` - Client's name
- `{link}` - Personalized booking URL

**Example Message:**
```
Hi John! Ready to level up your game? 🏒

Book your 1-on-1 session: https://schedule.forcehockeyiq.com?cid=12345&name=John&email=john@example.com

- ForceIQ Team
```

## Manual Operations

### Send Messages Now
1. Go to Dashboard tab
2. Click "Send Now" on Sunday Scheduler card
3. Messages will send to all clients immediately

### Export/Import Clients
1. Go to Settings tab
2. Click "Export Clients" → Saves JSON file
3. Click "Import Clients" → Select JSON file

### Test iMessage Connection
1. Go to Settings tab
2. Click "Test iMessage Connection"
3. Sends test message to verify Messages.app access

## Distribution

### For Shane (Internal Use)

**Option A: Direct .app Copy**
1. Build in Xcode (Product → Archive)
2. Distribute → Copy App
3. Send `.app` bundle via AirDrop or Dropbox
4. Shane: Control-click → Open to bypass Gatekeeper

**Option B: Developer ID Signed**
1. Set Team in Xcode (Signing & Capabilities)
2. Product → Archive
3. Distribute App → Developer ID
4. Upload for notarization
5. Export notarized .app
6. Shane can double-click to install

### App Sandbox Considerations

If you enable App Sandbox, add these entitlements:
- ✅ User Selected Files: Read/Write
- ✅ Network: Outgoing Connections (for future Google Calendar API)

For iMessage automation, **Sandbox must be disabled** or use temporary exception.

## Troubleshooting

### iMessage Not Sending
1. Check System Settings → Privacy & Security → Automation
2. Enable "ForceIQ Scheduler" access to Messages
3. Try "Test iMessage Connection" in Settings
4. Verify Messages.app is signed in with iMessage account

### Sunday Auto-Send Not Working
1. Verify "Sunday Auto-Send" is toggled ON in Settings
2. Check send time is set correctly
3. Ensure app is running on Sundays (or set Launch Agent)
4. Check Console.app for logs: filter "ForceIQ"

### Clients Not Saving
1. Data is stored in UserDefaults
2. Check ~/Library/Preferences/com.forcehockeyiq.scheduler.plist
3. Export clients as backup before updates

### App Won't Launch
1. Check macOS version (14.0+)
2. Right-click → Open (for unsigned builds)
3. System Settings → Privacy & Security → Allow app

## Launch Agent (Keep App Running)

To ensure Sunday messages send even if app is quit:

1. Create `~/Library/LaunchAgents/com.forcehockeyiq.scheduler.plist`:

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

2. Load the agent:
```bash
launchctl load ~/Library/LaunchAgents/com.forcehockeyiq.scheduler.plist
```

3. App will auto-start on login and stay running in background

## Architecture

```
ForceIQ Scheduler App (macOS)
├─ AppModel: Central state management
├─ StorageManager: UserDefaults persistence
├─ IMessageService: AppleScript-based message sending
├─ SundayScheduler: Timer-based automation
├─ GoogleAuthService: OAuth (future)
└─ Views:
   ├─ DashboardView: Command center with stats
   ├─ ClientsView: Client management
   ├─ AvailabilityView: Weekly schedule per coach
   └─ SettingsView: Configuration

Web Booking Page
├─ index.html: Coach selection UI
├─ app.js: Booking flow logic
└─ styles.css: ForceIQ branding

Vercel API
├─ /api/coaches: List coaches
├─ /api/availability: Get coach availability
└─ /api/book: Create booking in Google Calendar
```

## Data Flow

```
1. APP: Add client (John, john@email.com, +1234567890)
   └─> StorageManager.saveClients()

2. APP: Set availability (Chris: Mon 10-14, Tue 17-20)
   └─> StorageManager.saveConfig()

3. APP: Enable Sunday auto-send (9:00 AM)
   └─> SundayScheduler.configure()

4. SUNDAY 9:00 AM: Timer triggers
   └─> AppModel.sendSundayMessages()
       ├─ For each client:
       │  ├─ Generate link: schedule.forcehockeyiq.com?cid=123&name=John
       │  ├─ Replace {name} and {link} in template
       │  └─ IMessageService.sendMessage()
       └─ Update lastSentDate

5. CLIENT: Clicks link in iMessage
   └─> Web page loads
       ├─ Parse cid, name, email from URL
       ├─ Fetch /api/coaches
       ├─ User selects coach (Chris)
       ├─ Fetch /api/availability?coachId=chris
       ├─ User picks slot
       ├─ POST /api/book
       └─> Google Calendar event created
```

## Next Steps

### Phase 1: Test Current Implementation ✅
- [x] Build app in Xcode
- [x] Add test client
- [x] Test manual message send
- [x] Verify client storage
- [x] Test availability management

### Phase 2: Google Calendar Integration
- [ ] Implement Google OAuth flow
- [ ] Add Google Sign-In SDK for macOS
- [ ] Fetch real bookings from calendars
- [ ] Display in Dashboard

### Phase 3: Enhancements
- [ ] Import clients from Contacts.app
- [ ] Rich notifications (with booking details)
- [ ] Calendar sync indicator
- [ ] Message delivery confirmation
- [ ] Analytics dashboard

## Support

For issues or questions:
- Email: chris@forcehockeyiq.com
- Check logs: Console.app → filter "ForceIQ"
- Export clients before major updates

---

**ForceIQ Scheduler v2.0** - Elite. Automated. Simplified.
