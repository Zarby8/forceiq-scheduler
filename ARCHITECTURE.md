# ForceIQ Scheduler - Clean Architecture v2

## Overview
A focused scheduling system for 2 coaches to manage client bookings with automated iMessage reminders.

## Requirements

### Core Features
1. **Two coaches** with separate Google Calendars
2. **Weekly availability templates** - customizable per coach
3. **Automated Sunday iMessages** - sent to all clients with booking links
4. **Coach selection** - clients choose which coach they want
5. **Direct calendar booking** - books into coach's actual Google Calendar
6. **Reminder system** - notifications for coaches and clients

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    macOS App (SwiftUI)                      │
│  - Google OAuth for both coaches                           │
│  - Client management (name, phone, email)                  │
│  - Availability settings per coach                         │
│  - Automated Sunday iMessage sender                        │
│  - Booking dashboard view                                  │
│  - Manual reminder sender                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Vercel Edge Functions (Backend)                │
│  /api/coaches - List available coaches                     │
│  /api/availability - Get coach's free slots                │
│  /api/book - Create booking in Google Calendar             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│               Web Booking Page (React/Next.js)              │
│  1. Select coach                                           │
│  2. View availability                                      │
│  3. Pick time slot                                         │
│  4. Fill game details                                      │
│  5. Confirm booking                                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Google Calendar API                        │
│  - Coach 1's calendar                                      │
│  - Coach 2's calendar                                      │
│  - Direct read/write access                                │
└─────────────────────────────────────────────────────────────┘
```

## Data Models

### Coach Configuration
```typescript
interface Coach {
  id: string;              // "coach1" | "coach2"
  name: string;            // "Shane" | "Employee Name"
  email: string;           // Google account email
  calendarId: string;      // Google Calendar ID
  photoUrl?: string;       // Optional profile photo
  bio?: string;            // Optional bio
  weeklyHours: WeeklySchedule;
  color: string;           // Brand color for UI
}
```

### Weekly Schedule
```typescript
interface WeeklySchedule {
  0: TimeWindow[];  // Sunday
  1: TimeWindow[];  // Monday
  2: TimeWindow[];  // Tuesday
  3: TimeWindow[];  // Wednesday
  4: TimeWindow[];  // Thursday
  5: TimeWindow[];  // Friday
  6: TimeWindow[];  // Saturday
}

interface TimeWindow {
  start: string;    // "10:00"
  end: string;      // "14:00"
}
```

### Client
```typescript
interface Client {
  id: string;              // UUID
  name: string;
  phone: string;           // iMessage handle
  email: string;
  preferredCoach?: string; // Optional default
  createdAt: Date;
  lastMessageSent?: Date;
}
```

### Booking Request
```typescript
interface BookingRequest {
  coachId: string;
  clientId: string;
  clientName: string;
  clientEmail: string;
  clientPhone: string;
  startTime: number;       // Unix timestamp
  endTime: number;         // Unix timestamp
  timezone: string;
  gameDetails: {
    game: string;
    date: string;
    time: string;
    timezone: string;
    focus: string;
    performance: string;
    rating: number;
    events?: string;
    source: string;
  };
}
```

## API Endpoints

### GET /api/coaches
Returns list of available coaches.

**Response:**
```json
{
  "coaches": [
    {
      "id": "coach1",
      "name": "Shane",
      "photoUrl": "https://...",
      "bio": "Head coach with 15 years experience"
    },
    {
      "id": "coach2",
      "name": "Employee Name",
      "photoUrl": "https://...",
      "bio": "Assistant coach"
    }
  ]
}
```

### GET /api/availability?coachId={id}&week={offset}
Returns available time slots for specified coach.

**Parameters:**
- `coachId`: Coach identifier
- `week`: Week offset from current (0 = this week, 1 = next week)
- `tz`: Client timezone (optional)

**Response:**
```json
{
  "coach": {
    "id": "coach1",
    "name": "Shane"
  },
  "slots": [
    {
      "start": 1730649600000,
      "end": 1730653200000,
      "available": true
    }
  ]
}
```

### POST /api/book
Creates a booking in coach's Google Calendar.

**Request:**
```json
{
  "coachId": "coach1",
  "clientId": "uuid",
  "clientName": "Jane Doe",
  "clientEmail": "jane@example.com",
  "startTime": 1730649600000,
  "endTime": 1730653200000,
  "timezone": "America/Detroit",
  "gameDetails": { ... }
}
```

**Response:**
```json
{
  "success": true,
  "eventId": "google-calendar-event-id",
  "calendarLink": "https://calendar.google.com/..."
}
```

## Security

### Authentication
- **macOS App → Google Calendar**: OAuth 2.0 with offline refresh tokens
- **Web → API**: Simple auth token in environment (not per-client HMAC)
- **Client Links**: Include client ID for pre-fill only, not authentication

### Data Protection
- Coach credentials stored in macOS Keychain
- Google refresh tokens encrypted
- API auth token in Vercel environment variables
- No sensitive data in git repository

## Booking Flow

### 1. Sunday Morning Automation
```
09:00 AM Sunday → macOS App Timer Fires
  ↓
For each client in database:
  ↓
Generate link: https://schedule.forcehockeyiq.com?cid={clientId}
  ↓
Send iMessage: "Hi {name}! Book your ForceIQ session: {link}"
  ↓
Log sent status
```

### 2. Client Booking
```
Client clicks link
  ↓
Web page loads with clientId pre-filled
  ↓
1. SELECT COACH
   GET /api/coaches → Show coach cards
  ↓
2. VIEW AVAILABILITY
   GET /api/availability?coachId=coach1&week=0
  ↓
3. PICK SLOT
   Client selects time slot
  ↓
4. FILL DETAILS
   Game info, date, performance, etc.
  ↓
5. CONFIRM
   POST /api/book
   ↓
   Creates event in coach's Google Calendar
   ↓
   Sends confirmation email
   ↓
   Returns success
```

### 3. Reminder System

**24 Hours Before:**
- Google Calendar sends automatic email reminder to client
- (Configured in calendar event creation)

**1 Hour Before:**
- macOS app checks upcoming events (polling or calendar notifications)
- Sends notification to coach's Mac
- Optional: Send SMS reminder to client

## Implementation Phases

### Phase 1: Backend API ✅
- Create Vercel functions
- Implement Google Calendar API integration
- Build availability calculation logic
- Handle booking creation

### Phase 2: Web Booking Page ✅
- Add coach selection UI
- Display availability calendar
- Implement booking form
- Handle confirmation flow

### Phase 3: macOS App Core ✅
- Google OAuth integration
- Client management (CRUD)
- Availability settings UI
- View bookings from both calendars

### Phase 4: Automation ✅
- Sunday auto-send scheduler
- iMessage integration
- Template customization
- Send status tracking

### Phase 5: Reminders ✅
- Calendar event notification handling
- Coach notification system
- Manual reminder sender

### Phase 6: Polish ✅
- Error handling
- Loading states
- Offline support
- Documentation

## Environment Variables

```bash
# Google Calendar API (for backend)
GOOGLE_SERVICE_ACCOUNT_EMAIL=scheduler@project.iam.gserviceaccount.com
GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..."

# Coach Configuration
COACH_1_NAME=Shane
COACH_1_EMAIL=shane@forcehockeyiq.com
COACH_1_CALENDAR_ID=shane@forcehockeyiq.com
COACH_1_WEEKLY_HOURS={"1":[["10:00","14:00"]],"2":[["17:00","20:00"]]...}

COACH_2_NAME=Employee Name
COACH_2_EMAIL=employee@forcehockeyiq.com
COACH_2_CALENDAR_ID=employee@forcehockeyiq.com
COACH_2_WEEKLY_HOURS={"1":[["10:00","14:00"]]...}

# Email Configuration
OWNER_EMAILS=chris@forcehockeyiq.com,shaneb@forcehockeyiq.com

# API Security
API_AUTH_TOKEN=random-secret-token

# Timezone
TIMEZONE=America/Detroit
```

## File Structure

```
forceiq-scheduler/
├── api/                          # Vercel Edge Functions
│   ├── coaches.ts               # GET list of coaches
│   ├── availability.ts          # GET coach availability
│   └── book.ts                  # POST create booking
├── web/                         # Booking website
│   ├── app/                     # Next.js app router
│   │   ├── page.tsx            # Main booking page
│   │   └── components/
│   │       ├── CoachSelector.tsx
│   │       ├── Calendar.tsx
│   │       └── BookingForm.tsx
│   └── public/
│       └── coaches/             # Coach photos
├── CoachApp/                    # New focused macOS app
│   ├── CoachApp.swift          # App entry point
│   ├── Models/
│   │   ├── Coach.swift
│   │   ├── Client.swift
│   │   └── Booking.swift
│   ├── Services/
│   │   ├── GoogleCalendarService.swift
│   │   ├── ClientService.swift
│   │   └── MessageService.swift
│   ├── Views/
│   │   ├── DashboardView.swift
│   │   ├── ClientListView.swift
│   │   ├── AvailabilityView.swift
│   │   └── SettingsView.swift
│   └── Config.swift
├── shared/                      # Shared types/utilities
│   └── types.ts
├── .env.example
├── vercel.json
└── README.md
```

## Migration from Old System

1. Export client list from old app
2. Import into new app
3. Configure both coaches' Google OAuth
4. Set availability hours
5. Test booking flow
6. Archive old code
7. Deploy new system

## Success Metrics

- ✅ Both coaches can authenticate with Google
- ✅ Clients can select which coach they want
- ✅ Bookings go directly into correct coach's calendar
- ✅ Sunday messages sent automatically
- ✅ Reminders work for both coaches and clients
- ✅ Less than 2000 lines of code total
- ✅ Zero configuration files with CHANGE_ME
- ✅ Single source of truth for each concern
