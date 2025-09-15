import { googleCalendarRequest, googleSheetsRequest } from './_lib/google-auth.js'
import { verifySignature, formatAnswers, CONFIG } from './_lib/scheduling.js'

/**
 * Booking API endpoint
 * POST /api/booking
 */
export default async function handler(request) {
  // Handle CORS
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      }
    })
  }

  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const body = await request.json()
    const { action, cid, ts, sig, name, email, phone, answers, start, end, clientTz } = body

    // Handle different actions
    if (action === 'book') {
      return await handleBooking(body)
    } else if (action === 'cancel') {
      return await handleCancellation(body)
    } else if (action === 'reschedule') {
      return await handleReschedule(body)
    }

    return new Response(JSON.stringify({ error: 'Unknown action' }), {
      status: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    })

  } catch (error) {
    console.error('Booking API error:', error)
    return new Response(JSON.stringify({
      error: 'Booking failed',
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

async function handleBooking(body) {
  const { cid, ts, sig, name, email, phone, answers, start, end, clientTz } = body

  // Verify signature
  const isValidSignature = await verifySignature(cid, ts, sig)
  if (!isValidSignature) {
    return new Response(JSON.stringify({ ok: false, error: 'invalid_signature' }), {
      status: 401,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    })
  }

  // Create calendar event
  const startDate = new Date(start)
  const endDate = new Date(end)
  const timezone = clientTz || CONFIG.TIMEZONE
  const title = `ForceIQ Session – ${name}`
  const description = `Client: ${name} (${email || ''}, ${phone || ''})\\nCID: ${cid}\\nClient Timezone: ${timezone}\\n\\nAnswers:\\n${formatAnswers(answers)}`

  const eventData = {
    summary: title,
    description: description,
    start: {
      dateTime: startDate.toISOString(),
      timeZone: timezone
    },
    end: {
      dateTime: endDate.toISOString(),
      timeZone: timezone
    }
  }

  const calendarEvent = await googleCalendarRequest(
    `/calendars/${encodeURIComponent(CONFIG.CALENDAR_ID)}/events`,
    {
      method: 'POST',
      body: JSON.stringify(eventData)
    }
  )

  // Log to Google Sheets
  const sheetRow = [
    new Date().toISOString(),
    cid,
    name,
    email,
    phone,
    startDate.toISOString(),
    endDate.toISOString(),
    timezone,
    JSON.stringify(answers),
    calendarEvent.id
  ]

  await googleSheetsRequest(
    `/spreadsheets/${CONFIG.SHEET_ID}/values/Bookings:append?valueInputOption=USER_ENTERED`,
    {
      method: 'POST',
      body: JSON.stringify({
        values: [sheetRow]
      })
    }
  )

  // Send email notifications (using a simple service or skip for now)
  await sendNotifications(email, name, clientTz, startDate, endDate, answers)

  return new Response(JSON.stringify({
    ok: true,
    eventId: calendarEvent.id
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  })
}

async function handleCancellation(body) {
  const { cid, ts, sig, eventId } = body

  const isValidSignature = await verifySignature(cid, ts, sig)
  if (!isValidSignature) {
    return new Response(JSON.stringify({ ok: false, error: 'invalid_signature' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }

  try {
    await googleCalendarRequest(
      `/calendars/${encodeURIComponent(CONFIG.CALENDAR_ID)}/events/${eventId}`,
      { method: 'DELETE' }
    )

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ ok: false, error: 'not_found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }
}

async function handleReschedule(body) {
  const { cid, ts, sig, eventId, start, end } = body

  const isValidSignature = await verifySignature(cid, ts, sig)
  if (!isValidSignature) {
    return new Response(JSON.stringify({ ok: false, error: 'invalid_signature' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }

  try {
    const updateData = {
      start: { dateTime: new Date(start).toISOString() },
      end: { dateTime: new Date(end).toISOString() }
    }

    await googleCalendarRequest(
      `/calendars/${encodeURIComponent(CONFIG.CALENDAR_ID)}/events/${eventId}`,
      {
        method: 'PATCH',
        body: JSON.stringify(updateData)
      }
    )

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ ok: false, error: 'not_found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }
}

async function sendNotifications(clientEmail, name, timezone, startDate, endDate, answers) {
  // For now, we'll use a simple email service or skip this
  // In production, you could use Vercel's email integration, SendGrid, etc.

  const clientTimeStr = `${startDate.toLocaleString('en-US', {timeZone: timezone})} - ${endDate.toLocaleString('en-US', {timeZone: timezone})} (${timezone})`
  const emailBody = `Booked: ${clientTimeStr}\\n\\nDetails:\\n${formatAnswers(answers)}`

  // TODO: Implement email sending
  // For now, just log the notification
  console.log('Email notification:', { clientEmail, name, emailBody })
}