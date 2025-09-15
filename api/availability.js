import { googleCalendarRequest } from './_lib/google-auth.js'
import { generateTimeSlots, CONFIG } from './_lib/scheduling.js'

/**
 * Availability API endpoint
 * GET /api/availability?week=0&tz=America/Detroit
 */
export default async function handler(request) {
  // Handle CORS
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      }
    })
  }

  if (request.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const url = new URL(request.url)
    const weekOffset = parseInt(url.searchParams.get('week') || '0')
    const clientTz = url.searchParams.get('tz') || CONFIG.TIMEZONE
    const action = url.searchParams.get('action') || 'availability'

    // Handle signature verification endpoint
    if (action === 'verify') {
      const cid = url.searchParams.get('cid') || ''
      const ts = url.searchParams.get('ts') || ''
      const sig = url.searchParams.get('sig') || ''

      const { verifySignature } = await import('./_lib/scheduling.js')
      const isValid = await verifySignature(cid, ts, sig)

      return new Response(JSON.stringify({ ok: isValid }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      })
    }

    // Get calendar events for the week
    const now = new Date()
    const startOfWeek = new Date(now)
    startOfWeek.setDate(now.getDate() - now.getDay() + 1 + (weekOffset * 7)) // Monday
    startOfWeek.setHours(0, 0, 0, 0)

    const endOfWeek = new Date(startOfWeek)
    endOfWeek.setDate(startOfWeek.getDate() + 7)

    const timeMin = startOfWeek.toISOString()
    const timeMax = endOfWeek.toISOString()

    // Fetch events from Google Calendar
    const calendarData = await googleCalendarRequest(
      `/calendars/${encodeURIComponent(CONFIG.CALENDAR_ID)}/events?timeMin=${timeMin}&timeMax=${timeMax}&singleEvents=true&orderBy=startTime`
    )

    // Convert events to the format expected by our scheduling logic
    const events = (calendarData.items || []).map(event => {
      const start = event.start.dateTime ? new Date(event.start.dateTime) : new Date(event.start.date)
      const end = event.end.dateTime ? new Date(event.end.dateTime) : new Date(event.end.date)
      return {
        start: start.getTime(),
        end: end.getTime()
      }
    })

    // Generate available slots
    const slots = generateTimeSlots(events, weekOffset, clientTz)

    return new Response(JSON.stringify({ slots }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    })

  } catch (error) {
    console.error('Availability API error:', error)
    return new Response(JSON.stringify({
      error: 'Failed to fetch availability',
      details: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    })
  }
}