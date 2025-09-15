# ForceIQ Scheduler Website Setup Guide

This guide will help you deploy the booking website to `https://schedule.forcehockeyiq.com` and set up the Google Apps Script backend.

## Overview

The ForceIQ Scheduler consists of three parts:
1. **Web Booking Page** (`/web/` folder) - Client-facing booking interface
2. **Google Apps Script** (`/apps-script/` folder) - Backend API for calendar management
3. **macOS App** - Your client management and messaging tool

## Part 1: Google Apps Script Setup

### 1.1 Create Google Apps Script Project

1. Go to [script.google.com](https://script.google.com)
2. Click "New Project"
3. Replace the default code with the contents of `apps-script/Code.gs`
4. Name your project "ForceIQ Scheduler Backend"

### 1.2 Configure Settings

Update the CONFIG object in your Apps Script:

```javascript
const CONFIG = {
  CALENDAR_ID: 'YOUR_CALENDAR_ID@group.calendar.google.com',
  SHEET_ID: 'YOUR_GOOGLE_SHEET_ID',
  SLOT_MINUTES: 60,
  BUFFER_MINUTES: 15,
  TIMEZONE: 'America/Detroit', // Your timezone
  WORKING_HOURS: {
    // Use the Schedule Settings in your ForceIQ Scheduler app to generate this
    1: [['10:00', '14:00']], // Monday
    2: [['17:00', '20:00']], // Tuesday
    3: [['17:00', '20:00']], // Wednesday
    4: [['17:00', '20:00']], // Thursday
    5: [['10:00', '13:00']], // Friday
    6: [],                   // Saturday
    0: [['10:00', '14:00']], // Sunday
  },
  ORIGIN_ALLOWED: ['https://forcehockeyiq.com', 'https://schedule.forcehockeyiq.com'],
  HMAC_SECRET: 'GENERATE_32_CHAR_RANDOM_STRING_HERE',
  OWNER_EMAILS: ['coachzarby@gmail.com'], // Your notification emails
};
```

### 1.3 Set Up Google Calendar

1. Go to [calendar.google.com](https://calendar.google.com)
2. Create a new calendar called "ForceIQ Bookings"
3. Go to calendar settings → "Integrate calendar"
4. Copy the **Calendar ID** (looks like `abcd1234@group.calendar.google.com`)
5. Update `CALENDAR_ID` in your Apps Script

### 1.4 Set Up Google Sheet

1. Create a new Google Sheet called "ForceIQ Bookings"
2. Rename the first sheet to "Bookings"
3. Add headers: `Date | Client ID | Name | Email | Phone | Start | End | Answers | Event ID`
4. Get the Sheet ID from the URL (between `/d/` and `/edit`)
5. Update `SHEET_ID` in your Apps Script

### 1.5 Generate HMAC Secret

In your ForceIQ Scheduler app:
1. Open Settings
2. The HMAC secret is already generated
3. Copy it to the `HMAC_SECRET` field in Apps Script

### 1.6 Deploy Apps Script

1. Click "Deploy" → "New deployment"
2. Type: "Web app"
3. Execute as: "Me"
4. Who has access: "Anyone"
5. Click "Deploy"
6. **Copy the Web app URL** - you'll need this!

## Part 2: Website Deployment

### Option A: GitHub Pages (Free)

1. **Create GitHub Repository**
   ```bash
   cd /path/to/forceiq-scheduler
   git init
   git add .
   git commit -m "Initial ForceIQ Scheduler"
   gh repo create forceiq-scheduler --public
   git push origin main
   ```

2. **Set up GitHub Pages**
   - Go to repository Settings → Pages
   - Source: "Deploy from a branch"
   - Branch: `main`, folder: `/web`
   - Save

3. **Custom Domain**
   - In Pages settings, set custom domain: `schedule.forcehockeyiq.com`
   - Create CNAME record in your DNS: `schedule` → `yourusername.github.io`

### Option B: Netlify (Recommended)

1. **Deploy to Netlify**
   - Go to [netlify.com](https://netlify.com)
   - "New site from Git"
   - Connect your GitHub repo
   - Build settings: Publish directory: `web`
   - Deploy

2. **Custom Domain**
   - Site settings → Domain management
   - Add custom domain: `schedule.forcehockeyiq.com`
   - Follow DNS instructions

### Option C: Your Own Server

Upload the `web/` folder contents to your server at `schedule.forcehockeyiq.com`.

## Part 3: Configuration

### 3.1 Update Website Configuration

Edit `web/app.js` and update:

```javascript
const CONFIG = {
  API_BASE: 'https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec',
  // Replace YOUR_SCRIPT_ID with the ID from your Apps Script URL
};
```

### 3.2 Update ForceIQ Scheduler App

In your macOS app Settings:
1. **Web Base URL**: `https://schedule.forcehockeyiq.com`
2. **Google Apps Script URL**: Your deployed Apps Script URL
3. **HMAC Secret**: Should match Apps Script

### 3.3 Test the Setup

1. **Test Apps Script**:
   - Visit: `YOUR_APPS_SCRIPT_URL?action=availability`
   - Should return JSON with available slots

2. **Test Website**:
   - Visit: `https://schedule.forcehockeyiq.com`
   - Should load booking page and show available times

3. **Test Booking Flow**:
   - Make a test booking
   - Check Google Calendar for the event
   - Check Google Sheet for the logged data
   - Check your email for notifications

## Part 4: Advanced Setup

### SSL Certificate

Both GitHub Pages and Netlify provide free SSL. If using your own server:

```bash
# Using Certbot (Let's Encrypt)
sudo certbot --nginx -d schedule.forcehockeyiq.com
```

### DNS Configuration

Add these records to your domain:

```
Type: CNAME
Name: schedule
Value: yourusername.github.io  (or your hosting provider)

Type: A
Name: schedule
Value: [Your server IP]  (if using own server)
```

### Analytics (Optional)

Add Google Analytics to `web/index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

## Troubleshooting

### Common Issues

1. **"CORS Error"**
   - Ensure `ORIGIN_ALLOWED` in Apps Script includes your domain
   - Check that Apps Script is deployed with "Anyone" access

2. **"No Available Slots"**
   - Verify `WORKING_HOURS` configuration
   - Check calendar permissions
   - Ensure calendar isn't full of events

3. **"Booking Failed"**
   - Check HMAC secret matches between app and script
   - Verify calendar and sheet IDs are correct
   - Check Apps Script execution transcript for errors

4. **Website Not Loading**
   - Verify DNS settings
   - Check SSL certificate
   - Ensure all files uploaded to correct directory

### Getting Help

1. Check Apps Script execution transcript for errors
2. Use browser developer tools to check network requests
3. Verify all IDs and secrets are correctly copied

## Security Notes

- Keep your HMAC secret private
- Regularly rotate the HMAC secret for security
- Monitor your Google Apps Script execution quotas
- Use HTTPS everywhere
- Consider adding rate limiting if you get high traffic

---

Once set up, clients will visit `https://schedule.forcehockeyiq.com`, see your available times, book sessions, and everything will automatically sync to your calendar and ForceIQ Scheduler app!