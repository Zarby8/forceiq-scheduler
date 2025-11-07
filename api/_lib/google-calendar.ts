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
 * Get coach configuration from environment variables + KV storage
 */
export async function getCoaches(): Promise<Coach[]> {
  const coaches: Coach[] = [];

  // Coach 1
  if (process.env.COACH_1_CALENDAR_ID) {
    const weeklyHours = await getCoachAvailability('coach1');
    coaches.push({
      id: 'coach1',
      name: process.env.COACH_1_NAME || 'Coach 1',
      email: process.env.COACH_1_EMAIL || '',
      calendarId: process.env.COACH_1_CALENDAR_ID,
      photoUrl: process.env.COACH_1_PHOTO_URL,
      bio: process.env.COACH_1_BIO,
      weeklyHours,
      color: process.env.COACH_1_COLOR || '#F4C430',
    });
  }

  // Coach 2
  if (process.env.COACH_2_CALENDAR_ID) {
    const weeklyHours = await getCoachAvailability('coach2');
    coaches.push({
      id: 'coach2',
      name: process.env.COACH_2_NAME || 'Coach 2',
      email: process.env.COACH_2_EMAIL || '',
      calendarId: process.env.COACH_2_CALENDAR_ID,
      photoUrl: process.env.COACH_2_PHOTO_URL,
      bio: process.env.COACH_2_BIO,
      weeklyHours,
      color: process.env.COACH_2_COLOR || '#4FFF4F',
    });
  }

  return coaches;
}

/**
 * Get coach availability from environment variables
 */
function getCoachAvailability(coachId: string): WeeklySchedule {
  const defaultSchedule: WeeklySchedule = {
    0: [], // Sunday
    1: [], // Monday
    2: [], // Tuesday
    3: [], // Wednesday
    4: [], // Thursday
    5: [], // Friday
    6: [], // Saturday
  };

  const envKey = coachId === 'coach1' ? 'COACH_1_WEEKLY_HOURS' : 'COACH_2_WEEKLY_HOURS';
  const weeklyHoursJson = process.env[envKey];

  if (!weeklyHoursJson) {
    return defaultSchedule;
  }

  try {
    return JSON.parse(weeklyHoursJson) as WeeklySchedule;
  } catch (error) {
    console.error(`Failed to parse availability for ${coachId}:`, error);
    return defaultSchedule;
  }
}


/**
 * Get available time slots for a coach
 */
export async function getAvailableSlots(
  coach: Coach,
  weekOffset: number = 0
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
    guestsCanModify: true,  // Allow clients to cancel/reschedule
    guestsCanInviteOthers: false,
    guestsCanSeeOtherGuests: true,  // Let client see coach in attendees
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
  // In a production app, you'd integrate with SendGrid, AWS SES, or similar
  // For now, we'll rely on Google Calendar's built-in notifications
  console.log(`[Notification] New booking for ${coach.name}:`, {
    client: request.clientName,
    time: new Date(request.startTime).toLocaleString(),
    eventId: event.id,
  });
}

/**
 * Fetch upcoming bookings from all coaches' calendars
 */
export async function getUpcomingBookings(coaches: Coach[]): Promise<any[]> {
  const calendar = getCalendarClient();
  const now = new Date();
  const twoWeeksFromNow = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);

  const allBookings: any[] = [];

  for (const coach of coaches) {
    try {
      const response = await calendar.events.list({
        calendarId: coach.calendarId,
        timeMin: now.toISOString(),
        timeMax: twoWeeksFromNow.toISOString(),
        singleEvents: true,
        orderBy: 'startTime',
      });

      const events = response.data.items || [];

      for (const event of events) {
        // Only include ForceIQ sessions
        if (!event.summary?.includes('ForceIQ Session')) continue;

        const description = event.description || '';
        const gameDetails = parseGameDetailsFromDescription(description);

        allBookings.push({
          id: event.id,
          coachId: coach.id,
          coachName: coach.name,
          coachColor: coach.color,
          clientName: gameDetails.clientName || 'Unknown',
          clientEmail: gameDetails.clientEmail || '',
          startTime: event.start?.dateTime || event.start?.date || '',
          endTime: event.end?.dateTime || event.end?.date || '',
          game: gameDetails.game || '',
          date: gameDetails.date || '',
          time: gameDetails.time || '',
          timezone: gameDetails.timezone || '',
          focus: gameDetails.focus || '',
          performance: gameDetails.performance || '',
          rating: gameDetails.rating || '',
          source: gameDetails.source || '',
          events: gameDetails.events || '',
          calendarLink: event.htmlLink || '',
        });
      }
    } catch (error) {
      console.error(`Failed to fetch bookings for ${coach.name}:`, error);
    }
  }

  return allBookings.sort((a, b) =>
    new Date(a.startTime).getTime() - new Date(b.startTime).getTime()
  );
}

/**
 * Parse game details from calendar event description
 */
function parseGameDetailsFromDescription(description: string): any {
  const lines = description.split('\n');
  const details: any = {};

  for (const line of lines) {
    if (line.startsWith('Client: ')) {
      details.clientName = line.substring(8).trim();
    } else if (line.startsWith('Email: ')) {
      details.clientEmail = line.substring(7).trim();
    } else if (line.startsWith('Phone: ')) {
      details.clientPhone = line.substring(7).trim();
    } else if (line.startsWith('Timezone: ')) {
      details.clientTimezone = line.substring(10).trim();
    } else if (line.startsWith('Game: ')) {
      details.game = line.substring(6).trim();
    } else if (line.startsWith('Date: ')) {
      details.date = line.substring(6).trim();
    } else if (line.startsWith('Time: ')) {
      const match = line.match(/Time: (.+?) \((.+?)\)/);
      if (match) {
        details.time = match[1].trim();
        details.timezone = match[2].trim();
      }
    } else if (line.startsWith('Focus: ')) {
      details.focus = line.substring(7).trim();
    } else if (line.startsWith('Performance Rating: ')) {
      details.rating = line.substring(20).trim();
    } else if (line.startsWith('Self-Assessment: ')) {
      details.performance = line.substring(17).trim();
    } else if (line.startsWith('Source: ')) {
      details.source = line.substring(8).trim();
    } else if (line.startsWith('Events: ')) {
      details.events = line.substring(8).trim();
    }
  }

  return details;
}
