# ForceIQ Scheduler v2 - Deployment Guide

## Overview
This system consists of:
1. **Backend API** (Vercel Edge Functions) - handles availability & booking
2. **Web Booking Page** (Static HTML/JS/CSS) - client-facing booking interface
3. **macOS App** (SwiftUI) - coach dashboard for client management & automation

---

## Part 1: Deploy Backend & Website (Vercel)

### Prerequisites
- Google Cloud project with Calendar API enabled
- Service account with JSON key
- Two Google Calendars (one per coach)
- Vercel account

### Step 1: Set Up Google Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable **Google Calendar API**:
   - APIs & Services → Library → Search "Google Calendar API" → Enable
4. Create Service Account:
   - IAM & Admin → Service Accounts → Create Service Account
   - Name: "ForceIQ Scheduler"
   - Role: None needed
   - Create & Continue → Done
5. Generate Key:
   - Click on service account → Keys tab → Add Key → Create new key → JSON
   - Download and save the JSON file securely
6. Note the `client_email` from JSON file (looks like `scheduler@project-id.iam.gserviceaccount.com`)

### Step 2: Set Up Google Calendars

For **each coach** (you + employee):

1. Create dedicated Google Calendar:
   - Go to Google Calendar → Settings → Add calendar → Create new calendar
   - Name: "ForceIQ - [Coach Name]"
   - Or use existing personal calendar
2. Share with Service Account:
   - Calendar Settings → Share with specific people
   - Add service account email from Step 1
   - Permission: **Make changes to events**
3. Get Calendar ID:
   - Calendar Settings → Integrate calendar → Copy "Calendar ID"
   - Usually looks like: `yourname@gmail.com` or `random-id@group.calendar.google.com`

### Step 3: Deploy to Vercel

1. Push this code to GitHub if not already there
2. Go to [Vercel Dashboard](https://vercel.com/dashboard)
3. Click "Add New" → "Project"
4. Import your GitHub repository
5. Click "Deploy" (it will fail initially - that's OK, we need to add environment variables)

### Step 4: Configure Environment Variables in Vercel

In Vercel Dashboard → Your Project → Settings → Environment Variables, add:

```bash
# Google Service Account (from JSON file)
GOOGLE_SERVICE_ACCOUNT_EMAIL=scheduler@your-project.iam.gserviceaccount.com
GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# Coach 1 (You)
COACH_1_NAME=Shane
COACH_1_EMAIL=shane@forcehockeyiq.com
COACH_1_CALENDAR_ID=shane@forcehockeyiq.com
COACH_1_PHOTO_URL=https://example.com/shane.jpg (optional)
COACH_1_BIO=Head coach with 15 years of experience
COACH_1_COLOR=#F4C430
COACH_1_WEEKLY_HOURS={"1":[["10:00","14:00"]],"2":[["17:00","20:00"]],"3":[["17:00","20:00"]],"4":[["17:00","20:00"]],"5":[["10:00","13:00"]],"6":[],"0":[]}

# Coach 2 (Employee)
COACH_2_NAME=Employee Name
COACH_2_EMAIL=employee@forcehockeyiq.com
COACH_2_CALENDAR_ID=employee@forcehockeyiq.com
COACH_2_PHOTO_URL=https://example.com/employee.jpg (optional)
COACH_2_BIO=Assistant coach specializing in skill development
COACH_2_COLOR=#4FFF4F
COACH_2_WEEKLY_HOURS={"1":[["10:00","14:00"]],"2":[["17:00","20:00"]],"3":[["17:00","20:00"]],"4":[["17:00","20:00"]],"5":[["10:00","13:00"]],"6":[],"0":[]}

# General Configuration
TIMEZONE=America/Detroit
OWNER_EMAILS=chris@forcehockeyiq.com,shaneb@forcehockeyiq.com
```

**Important notes:**
- For `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`: Copy entire key from JSON including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`, with `\n` for newlines
- `WEEKLY_HOURS` format: `{"0":[],"1":[["09:00","17:00"]],...,"6":[]}` where 0=Sunday, 1=Monday, etc.
- Times are in 24-hour format in the coach's timezone

### Step 5: Redeploy

1. Go to Vercel → Deployments tab
2. Click "Redeploy" or push a new commit to GitHub
3. Wait for deployment to complete
4. Visit your URL (e.g., `https://forceiq-scheduler.vercel.app`)

### Step 6: Test the Website

1. Visit `https://your-deployment-url.vercel.app`
2. You should see the coach selection cards
3. Select a coach → availability should load
4. Try booking a test slot
5. Check Google Calendar to confirm event was created

---

## Part 2: Set Up macOS App (Coming Next)

The macOS app will allow you to:
- Manage client list (name, phone, email)
- Set availability hours for both coaches
- Send automated Sunday iMessages to all clients
- View upcoming bookings
- Send manual reminders

**Status**: Under development - see next section

---

## Weekly Hours Format

The `WEEKLY_HOURS` is a JSON object where:
- Keys are day of week: `0` = Sunday, `1` = Monday, ..., `6` = Saturday
- Values are arrays of time windows: `[["start", "end"], ...]`
- Times are in 24-hour format (HH:MM)

Example:
```json
{
  "0": [],
  "1": [["10:00", "14:00"]],
  "2": [["17:00", "20:00"]],
  "3": [["17:00", "20:00"]],
  "4": [["17:00", "20:00"]],
  "5": [["10:00", "13:00"]],
  "6": []
}
```

This means:
- Sunday: Closed
- Monday: 10 AM - 2 PM
- Tuesday-Thursday: 5 PM - 8 PM
- Friday: 10 AM - 1 PM
- Saturday: Closed

---

## Updating Availability Hours

To change a coach's working hours:
1. Go to Vercel Dashboard → Settings → Environment Variables
2. Find `COACH_X_WEEKLY_HOURS`
3. Click Edit
4. Update the JSON
5. Save
6. Redeploy the project

---

## Troubleshooting

### "Failed to load coaches"
- Check Vercel logs for errors
- Verify environment variables are set correctly
- Ensure service account email is correct

### "Failed to load availability"
- Check that calendar is shared with service account
- Verify CALENDAR_ID is correct
- Check Vercel function logs

### "Booking failed"
- Verify service account has "Make changes to events" permission
- Check Google Calendar API is enabled
- Review Vercel logs for detailed error

### How to check Vercel logs:
1. Vercel Dashboard → Your Project → Functions
2. Click on a function (e.g., `/api/book`)
3. View logs in real-time or historical logs

---

## Next Steps

1. ✅ Deploy backend & website
2. ⏳ Build macOS app for client management
3. ⏳ Implement Sunday auto-send feature
4. ⏳ Add reminder system
5. ⏳ Test end-to-end flow

---

## Support

For issues or questions:
- Check Vercel deployment logs
- Review Google Calendar API quotas
- Verify all environment variables match your actual resources
