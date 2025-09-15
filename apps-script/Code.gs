/**
 * ForceIQ Scheduler – Google Apps Script backend
 * Publishes availability and books events into Google Calendar.
 * Stores rows in Google Sheets and emails confirmations.
 */

const CONFIG = {
  CALENDAR_ID: 'CHANGE_ME@group.calendar.google.com', // dedicated bookings calendar
  SHEET_ID: 'CHANGE_ME_SHEET_ID', // Google Sheet to log bookings
  SLOT_MINUTES: 60,             // session length
  BUFFER_MINUTES: 15,           // buffer before & after
  TIMEZONE: 'America/Detroit',  // your timezone
  WORKING_HOURS: {              // weekly windows for availability
    // weekday: [ [start, end], ... ] in 24h local time
    1: [['10:00', '14:00']], // Monday
    2: [['17:00', '20:00']],
    3: [['17:00', '20:00']],
    4: [['17:00', '20:00']],
    5: [['10:00', '13:00']],
    6: [],                    // Saturday
    0: [['10:00', '14:00']], // Sunday
  },
  ORIGIN_ALLOWED: ['https://forcehockeyiq.com', 'https://schedule.forcehockeyiq.com'],
  HMAC_SECRET: 'CHANGE_ME_TO_RANDOM_32+_CHARS',
  OWNER_EMAILS: ['chris@forcehockeyiq.com', 'shaneb@forcehockeyiq.com'],
};

function doGet(e) {
  const action = (e.parameter.action || 'availability');
  enableCors();
  if (action === 'availability') {
    const week = parseInt(e.parameter.week || '0', 10);
    const tz = e.parameter.tz || CONFIG.TIMEZONE;
    const slots = getAvailability(week, tz);
    return json(slots);
  }
  if (action === 'verify') {
    const ok = verifySig(e.parameter);
    return json({ ok });
  }
  return json({ error: 'unknown action' }, 400);
}

function doPost(e) {
  enableCors();
  const body = e.postData && e.postData.contents ? JSON.parse(e.postData.contents) : {};
  const action = body.action;
  if (action === 'book') return json(book(body));
  if (action === 'cancel') return json(cancel(body));
  if (action === 'reschedule') return json(reschedule(body));
  return json({ error: 'unknown action' }, 400);
}

function getAvailability(weekOffset, tz) {
  const cal = CalendarApp.getCalendarById(CONFIG.CALENDAR_ID);
  const now = new Date();
  const startOfWeek = shiftToWeekStart(now, weekOffset, CONFIG.TIMEZONE);
  const endOfWeek = new Date(startOfWeek.getTime() + 7 * 24 * 3600 * 1000);

  const events = cal.getEvents(startOfWeek, endOfWeek).map(e => ({
    start: e.getStartTime().getTime(),
    end: e.getEndTime().getTime(),
  }));

  const slots = [];
  for (let d = 0; d < 7; d++) {
    const day = new Date(startOfWeek.getTime() + d * 24 * 3600 * 1000);
    const dow = day.getDay();
    const windows = CONFIG.WORKING_HOURS[dow] || [];
    windows.forEach(([s, e]) => {
      const [sh, sm] = s.split(':').map(Number);
      const [eh, em] = e.split(':').map(Number);
      const winStart = new Date(day); winStart.setHours(sh, sm, 0, 0);
      const winEnd = new Date(day); winEnd.setHours(eh, em, 0, 0);
      let t = new Date(winStart);
      while (t < winEnd) {
        const slotStart = new Date(t);
        const slotEnd = new Date(slotStart.getTime() + CONFIG.SLOT_MINUTES * 60000);
        const blocked = intersects(events, slotStart, slotEnd, CONFIG.BUFFER_MINUTES);
        if (!blocked && slotEnd <= winEnd) {
          slots.push({ start: slotStart.getTime(), end: slotEnd.getTime(), tz: CONFIG.TIMEZONE });
        }
        t = new Date(t.getTime() + CONFIG.SLOT_MINUTES * 60000);
      }
    });
  }
  return { slots };
}

function intersects(events, s, e, bufferMin) {
  const sb = s.getTime() - bufferMin * 60000;
  const eb = e.getTime() + bufferMin * 60000;
  return events.some(ev => !(ev.end <= sb || ev.start >= eb));
}

function shiftToWeekStart(date, offset, tz) {
  const d = new Date(date);
  const dow = d.getDay();
  const diff = d.getDate() - dow + (dow === 0 ? -6 : 1); // Monday-start
  const monday = new Date(d.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  const target = new Date(monday.getTime() + offset * 7 * 24 * 3600 * 1000);
  return target;
}

function verifySig(params) {
  const cid = params.cid || '';
  const ts = params.ts || '';
  const sig = params.sig || '';
  const raw = `${cid}|${ts}`;
  const signed = Utilities.computeHmacSha256Signature(raw, CONFIG.HMAC_SECRET);
  const b64 = Utilities.base64EncodeWebSafe(signed).replace(/=+$/, '');
  return b64 === sig && Date.now() - Number(ts) * 1000 < 30 * 24 * 3600 * 1000; // 30 days
}

function book(body) {
  if (!verifySig(body)) return { ok: false, error: 'invalid_signature' };
  const { cid, name, email, phone, answers, start, end } = body;
  const cal = CalendarApp.getCalendarById(CONFIG.CALENDAR_ID);
  const s = new Date(start), e = new Date(end);
  const title = `ForceIQ Session – ${name}`;
  const desc = `Client: ${name} (${email || ''}, ${phone || ''})\nCID: ${cid}\n\nAnswers:\n${formatAnswers(answers)}`;
  const event = cal.createEvent(title, s, e, { description: desc });
  const row = [new Date(), cid, name, email, phone, s, e, JSON.stringify(answers), event.getId()];
  const sheet = SpreadsheetApp.openById(CONFIG.SHEET_ID).getSheetByName('Bookings') || SpreadsheetApp.openById(CONFIG.SHEET_ID).insertSheet('Bookings');
  sheet.appendRow(row);
  try { MailApp.sendEmail(email, 'ForceIQ Booking Confirmed', `Booked: ${s} - ${e}\n\nDetails:\n${formatAnswers(answers)}`); } catch (e) {}
  CONFIG.OWNER_EMAILS.forEach(addr => { try { MailApp.sendEmail(addr, 'New ForceIQ Booking', `${name} booked ${s} - ${e}\n\n${formatAnswers(answers)}`); } catch (e) {} });
  return { ok: true, eventId: event.getId() };
}

function cancel(body) {
  if (!verifySig(body)) return { ok: false, error: 'invalid_signature' };
  const { eventId } = body;
  const cal = CalendarApp.getCalendarById(CONFIG.CALENDAR_ID);
  const ev = cal.getEventById(eventId);
  if (!ev) return { ok: false, error: 'not_found' };
  ev.deleteEvent();
  return { ok: true };
}

function reschedule(body) {
  if (!verifySig(body)) return { ok: false, error: 'invalid_signature' };
  const { eventId, start, end } = body;
  const cal = CalendarApp.getCalendarById(CONFIG.CALENDAR_ID);
  const ev = cal.getEventById(eventId);
  if (!ev) return { ok: false, error: 'not_found' };
  ev.setTime(new Date(start), new Date(end));
  return { ok: true };
}

function formatAnswers(ans) {
  if (!ans) return '';
  const lines = [];
  for (var k in ans) lines.push(`${k}: ${ans[k]}`);
  return lines.join('\n');
}

function json(obj, code) {
  const output = ContentService.createTextOutput(JSON.stringify(obj));
  output.setMimeType(ContentService.MimeType.JSON);
  return output;
}

function enableCors() {
  // Apps Script Web Apps do not expose headers directly here; CORS handled by browser if same-origin
}

