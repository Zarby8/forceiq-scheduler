// Configure these
const GAS_BASE = 'https://script.google.com/macros/s/AKfycbwYYyVTh_5voqqPHMm8mQf4S23LS9LFv-P6bALnKBkid5x0o5g5yNLMpOACfSpi4pXGFA/exec';

let weekOffset = 0;
let selectedSlot = null;

const qs = new URLSearchParams(location.search);
const cid = qs.get('cid') || '';
const nameParam = qs.get('name') || '';
const emailParam = qs.get('email') || '';
const ts = qs.get('ts') || '';
const sig = qs.get('sig') || '';

document.addEventListener('DOMContentLoaded', () => {
  if (nameParam) document.getElementById('name').value = nameParam;
  if (emailParam) document.getElementById('email').value = emailParam;
  if (nameParam) document.getElementById('welcome').textContent = `Welcome, ${nameParam}. Select a slot and answer questions.`;

  document.getElementById('prevWeek').addEventListener('click', () => { weekOffset = Math.max(weekOffset - 1, 0); loadAvailability(); });
  document.getElementById('nextWeek').addEventListener('click', () => { weekOffset += 1; loadAvailability(); });
  document.getElementById('submit').addEventListener('click', submitBooking);

  loadAvailability();
});

async function loadAvailability(){
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const url = `${GAS_BASE}?action=availability&week=${weekOffset}&tz=${encodeURIComponent(tz)}`;
  const res = await fetch(url);
  const data = await res.json();
  renderSlots(data.slots || []);
}

function renderSlots(slots){
  const cont = document.getElementById('slots');
  cont.innerHTML = '';
  selectedSlot = null;
  const fmt = (t) => new Date(Number(t)).toLocaleString([], {hour:'2-digit', minute:'2-digit', weekday:'short', month:'short', day:'numeric'});
  if (!slots.length){
    cont.textContent = 'No slots available in this window.';
    return;
  }
  const first = new Date(Number(slots[0].start));
  const last = new Date(Number(slots[slots.length-1].end));
  document.getElementById('weekLabel').textContent = `${first.toLocaleDateString()} – ${last.toLocaleDateString()}`;
  slots.forEach(s => {
    const btn = document.createElement('button');
    btn.className = 'slot';
    btn.textContent = `${fmt(s.start)} → ${fmt(s.end)}`;
    btn.addEventListener('click', () => {
      document.querySelectorAll('.slot').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      selectedSlot = s;
    });
    cont.appendChild(btn);
  });
}

async function submitBooking(){
  const status = document.getElementById('status');
  status.textContent = '';
  const name = document.getElementById('name').value.trim();
  const email = document.getElementById('email').value.trim();
  const phone = document.getElementById('phone').value.trim();
  const answers = {
    game: document.getElementById('q_game').value.trim(),
    video: document.getElementById('q_video').value.trim(),
    focus: document.getElementById('q_focus').value.trim(),
    constraints: document.getElementById('q_constraints').value.trim(),
  };
  if (!cid || !ts || !sig) { status.textContent = 'Invalid link. Please contact ForceIQ.'; return; }
  if (!name || !email) { status.textContent = 'Name and email are required.'; return; }
  if (!selectedSlot) { status.textContent = 'Please select a slot.'; return; }
  if (!answers.game || !answers.video || !answers.focus) { status.textContent = 'Please answer all required questions.'; return; }

  const clientTz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const payload = { action:'book', cid, ts, sig, name, email, phone, answers, start: selectedSlot.start, end: selectedSlot.end, clientTz };
  const res = await fetch(GAS_BASE, { method:'POST', headers: { 'Content-Type':'application/json' }, body: JSON.stringify(payload)});
  const data = await res.json();
  if (data.ok) {
    status.textContent = 'Booked. You will receive a confirmation email.';
  } else {
    status.textContent = 'Booking failed: ' + (data.error || 'Unknown error');
  }
}

