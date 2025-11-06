// Google Calendar API helper
import { google } from 'googleapis';
import type { Coach, TimeSlot, WeeklySchedule } from '../../shared/types';

const SLOT_MINUTES = 60;
const BUFFER_MINUTES = 15;

/**
 * Get Google Calendar API client using service account
 */
export function getCalendarClient() {
  const auth = new google.auth.GoogleAuth({
    credentials: {
      client_email: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
      private_key: process.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    },
    scopes: ['https://www.googleapis.com/auth/calendar'],
  });

  return google.calendar({ version: 'v3', auth });
}

/**
 * Get coach configuration from environment variables
 */
export function getCoaches(): Coach[] {
  const coaches: Coach[] = [];

  // Coach 1
  if (process.env.COACH_1_CALENDAR_ID) {
    coaches.push({
      id: 'coach1',
      name: process.env.COACH_1_NAME || 'Coach 1',
      email: process.env.COACH_1_EMAIL || '',
      calendarId: process.env.COACH_1_CALENDAR_ID,
      photoUrl: process.env.COACH_1_PHOTO_URL,
      bio: process.env.COACH_1_BIO,
      weeklyHours: parseWeeklyHours(process.env.COACH_1_WEEKLY_HOURS),
      color: process.env.COACH_1_COLOR || '#F4C430',
    });
  }

  // Coach 2
  if (process.env.COACH_2_CALENDAR_ID) {
    coaches.push({
      id: 'coach2',
      name: process.env.COACH_2_NAME || 'Coach 2',
      email: process.env.COACH_2_EMAIL || '',
      calendarId: process.env.COACH_2_CALENDAR_ID,
      photoUrl: process.env.COACH_2_PHOTO_URL,
      bio: process.env.COACH_2_BIO,
      weeklyHours: parseWeeklyHours(process.env.COACH_2_WEEKLY_HOURS),
      color: process.env.COACH_2_COLOR || '#4FFF4F',
    });
  }

  return coaches;
}

/**
 * Parse weekly hours from JSON string
 */
function parseWeeklyHours(json?: string): WeeklySchedule {
  const defaultSchedule: WeeklySchedule = {
    0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []
  };

  if (!json) return defaultSchedule;

  try {
    return JSON.parse(json) as WeeklySchedule;
  } catch {
    return defaultSchedule;
  }
}

/**
 * Get available time slots for a coach
 */
export async function getAvailableSlots(
  coach: Coach,
  weekOffset: number = 0,
  timezone: string = process.env.TIMEZONE || 'America/Detroit'
): Promise<TimeSlot[]> {
  const calendar = getCalendarClient();

  // Calculate week boundaries
  const now = new Date();
  const startOfWeek = getWeekStart(now, weekOffset);
  const endOfWeek = new Date(startOfWeek.getTime() + 7 * 24 * 60 * 60 * 1000);

  // Fetch existing events
  const response = await calendar.events.list({
    calendarId: coach.calendarId,
    timeMin: startOfWeek.toISOString(),
    timeMax: endOfWeek.toISOString(),
    singleEvents: true,
    orderBy: 'startTime',
  });

  const existingEvents = (response.data.items || []).map(event => ({
    start: new Date(event.start?.dateTime || event.start?.date || '').getTime(),
    end: new Date(event.end?.dateTime || event.end?.date || '').getTime(),
  }));

  // Generate potential slots based on weekly hours
  const slots: TimeSlot[] = [];

  for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
    const day = new Date(startOfWeek.getTime() + dayOffset * 24 * 60 * 60 * 1000);
    const dayOfWeek = day.getDay() as keyof WeeklySchedule;
    const windows = coach.weeklyHours[dayOfWeek] || [];

    for (const window of windows) {
      const [startHour, startMin] = window.start.split(':').map(Number);
      const [endHour, endMin] = window.end.split(':').map(Number);

      const windowStart = new Date(day);
      windowStart.setHours(startHour, startMin, 0, 0);

      const windowEnd = new Date(day);
      windowEnd.setHours(endHour, endMin, 0, 0);

      let currentSlot = new Date(windowStart);

      while (currentSlot < windowEnd) {
        const slotStart = new Date(currentSlot);
        const slotEnd = new Date(currentSlot.getTime() + SLOT_MINUTES * 60 * 1000);

        // Don't create slots in the past
        if (slotStart > now && slotEnd <= windowEnd) {
          const isBlocked = isSlotBlocked(slotStart, slotEnd, existingEvents);

          slots.push({
            start: slotStart.getTime(),
            end: slotEnd.getTime(),
            available: !isBlocked,
          });
        }

        currentSlot = new Date(currentSlot.getTime() + SLOT_MINUTES * 60 * 1000);
      }
    }
  }

  return slots.filter(slot => slot.available);
}

/**
 * Check if a slot conflicts with existing events (including buffer time)
 */
function isSlotBlocked(
  slotStart: Date,
  slotEnd: Date,
  existingEvents: Array<{ start: number; end: number }>
): boolean {
  const bufferMs = BUFFER_MINUTES * 60 * 1000;
  const slotStartWithBuffer = slotStart.getTime() - bufferMs;
  const slotEndWithBuffer = slotEnd.getTime() + bufferMs;

  return existingEvents.some(event => {
    return !(event.end <= slotStartWithBuffer || event.start >= slotEndWithBuffer);
  });
}

/**
 * Get the start of the week (Monday at 00:00) with offset
 */
function getWeekStart(date: Date, weekOffset: number = 0): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust for Monday start
  const monday = new Date(d.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  return new Date(monday.getTime() + weekOffset * 7 * 24 * 60 * 60 * 1000);
}

/**
 * Create a booking in Google Calendar
 */
export async function createBooking(
  coach: Coach,
  request: {
    clientName: string;
    clientEmail: string;
    clientPhone?: string;
    startTime: number;
    endTime: number;
    timezone: string;
    gameDetails: any;
  }
) {
  const calendar = getCalendarClient();

  const startDate = new Date(request.startTime);
  const endDate = new Date(request.endTime);

  const description = `
Client: ${request.clientName}
Email: ${request.clientEmail}
Phone: ${request.clientPhone || 'N/A'}
Timezone: ${request.timezone}

Game Details:
Game: ${request.gameDetails.game}
Date: ${request.gameDetails.date}
Time: ${request.gameDetails.time} (${request.gameDetails.timezone})
Focus: ${request.gameDetails.focus}
Performance Rating: ${request.gameDetails.rating}/10
Self-Assessment: ${request.gameDetails.performance}
Source: ${request.gameDetails.source}
${request.gameDetails.events ? `Events: ${request.gameDetails.events}` : ''}
  `.trim();

  const event = {
    summary: `ForceIQ Session - ${request.clientName}`,
    description,
    start: {
      dateTime: startDate.toISOString(),
      timeZone: request.timezone,
    },
    end: {
      dateTime: endDate.toISOString(),
      timeZone: request.timezone,
    },
    attendees: [
      { email: request.clientEmail, displayName: request.clientName },
      { email: coach.email, displayName: coach.name },
    ],
    reminders: {
      useDefault: false,
      overrides: [
        { method: 'email', minutes: 24 * 60 }, // 24 hours before
        { method: 'popup', minutes: 60 },       // 1 hour before
      ],
    },
    guestsCanModify: false,
    guestsCanInviteOthers: false,
    guestsCanSeeOtherGuests: false,
  };

  const response = await calendar.events.insert({
    calendarId: coach.calendarId,
    requestBody: event,
    sendUpdates: 'all', // Send email notifications
  });

  // Send notification to owners
  await sendOwnerNotification(coach, request, response.data);

  return {
    eventId: response.data.id,
    calendarLink: response.data.htmlLink,
  };
}

/**
 * Send notification email to owners
 */
async function sendOwnerNotification(coach: Coach, request: any, event: any) {
  const ownerEmails = process.env.OWNER_EMAILS?.split(',').map(e => e.trim()) || [];

  // In a production app, you'd integrate with SendGrid, AWS SES, or similar
  // For now, we'll rely on Google Calendar's built-in notifications
  console.log(`[Notification] New booking for ${coach.name}:`, {
    client: request.clientName,
    time: new Date(request.startTime).toLocaleString(),
    eventId: event.id,
  });
}
