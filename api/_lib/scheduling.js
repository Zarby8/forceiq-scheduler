/**
 * Scheduling utility functions
 * Port of Apps Script logic to modern JavaScript
 */

export const CONFIG = {
  SLOT_MINUTES: parseInt(process.env.SLOT_MINUTES || '60'),
  BUFFER_MINUTES: parseInt(process.env.BUFFER_MINUTES || '15'),
  TIMEZONE: process.env.TIMEZONE || 'America/Detroit',
  WORKING_HOURS: JSON.parse(process.env.WORKING_HOURS || '{}'),
  CALENDAR_ID: process.env.GOOGLE_CALENDAR_ID,
  SHEET_ID: process.env.GOOGLE_SHEET_ID,
  HMAC_SECRET: process.env.HMAC_SECRET,
  OWNER_EMAILS: process.env.OWNER_EMAILS?.split(',') || []
}

/**
 * Get start of week (Monday) with offset
 */
export function shiftToWeekStart(date, offset, timezone) {
  const d = new Date(date)
  const dow = d.getDay()
  const diff = d.getDate() - dow + (dow === 0 ? -6 : 1) // Monday-start
  const monday = new Date(d.setDate(diff))
  monday.setHours(0, 0, 0, 0)
  const target = new Date(monday.getTime() + offset * 7 * 24 * 3600 * 1000)
  return target
}

/**
 * Check if events intersect with buffer time
 */
export function intersects(events, slotStart, slotEnd, bufferMin) {
  const sb = slotStart.getTime() - bufferMin * 60000
  const eb = slotEnd.getTime() + bufferMin * 60000
  return events.some(ev => !(ev.end <= sb || ev.start >= eb))
}

/**
 * Generate available time slots for a week
 */
export function generateTimeSlots(events, weekOffset, clientTz) {
  const now = new Date()
  const startOfWeek = shiftToWeekStart(now, weekOffset, CONFIG.TIMEZONE)
  const endOfWeek = new Date(startOfWeek.getTime() + 7 * 24 * 3600 * 1000)

  const slots = []

  for (let d = 0; d < 7; d++) {
    const day = new Date(startOfWeek.getTime() + d * 24 * 3600 * 1000)
    const dow = day.getDay()
    const windows = CONFIG.WORKING_HOURS[dow] || []

    windows.forEach(([startTime, endTime]) => {
      const [sh, sm] = startTime.split(':').map(Number)
      const [eh, em] = endTime.split(':').map(Number)

      const winStart = new Date(day)
      winStart.setHours(sh, sm, 0, 0)

      const winEnd = new Date(day)
      winEnd.setHours(eh, em, 0, 0)

      let t = new Date(winStart)
      while (t < winEnd) {
        const slotStart = new Date(t)
        const slotEnd = new Date(slotStart.getTime() + CONFIG.SLOT_MINUTES * 60000)

        const blocked = intersects(events, slotStart, slotEnd, CONFIG.BUFFER_MINUTES)

        if (!blocked && slotEnd <= winEnd) {
          slots.push({
            start: slotStart.getTime(),
            end: slotEnd.getTime(),
            serverTz: CONFIG.TIMEZONE,
            clientTz: clientTz || CONFIG.TIMEZONE
          })
        }

        t = new Date(t.getTime() + CONFIG.SLOT_MINUTES * 60000)
      }
    })
  }

  return slots
}

/**
 * Verify HMAC signature
 */
export async function verifySignature(cid, ts, sig) {
  if (!cid || !ts || !sig || !CONFIG.HMAC_SECRET) {
    return false
  }

  const raw = `${cid}|${ts}`
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(CONFIG.HMAC_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(raw))
  const b64 = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/=+$/, '')

  const isValid = b64 === sig
  const isNotExpired = Date.now() - Number(ts) * 1000 < 30 * 24 * 3600 * 1000 // 30 days

  return isValid && isNotExpired
}

/**
 * Format answers object for email/logging
 */
export function formatAnswers(answers) {
  if (!answers) return ''
  return Object.entries(answers)
    .map(([key, value]) => `${key}: ${value}`)
    .join('\n')
}