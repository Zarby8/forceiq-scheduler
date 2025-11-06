// ForceIQ Scheduler - Updated with Coach Selection
const API_BASE = window.location.hostname === 'localhost'
  ? 'http://localhost:3000/api'
  : 'https://schedule.forcehockeyiq.com/api';

let weekOffset = 0;
let selectedSlot = null;
let selectedCoach = null;
let coaches = [];

const qs = new URLSearchParams(location.search);
const cid = qs.get('cid') || '';
const nameParam = qs.get('name') || '';
const emailParam = qs.get('email') || '';

document.addEventListener('DOMContentLoaded', async () => {
  // Pre-fill client info if provided
  if (nameParam) {
    document.getElementById('name').value = nameParam;
    document.getElementById('welcome').textContent = `Welcome, ${nameParam}. Select your coach and pick a time slot.`;
  }
  if (emailParam) document.getElementById('email').value = emailParam;

  // Load coaches
  await loadCoaches();

  // Event listeners
  document.getElementById('prevWeek').addEventListener('click', () => {
    weekOffset = Math.max(weekOffset - 1, 0);
    loadAvailability();
  });
  document.getElementById('nextWeek').addEventListener('click', () => {
    weekOffset += 1;
    loadAvailability();
  });
  document.getElementById('submit').addEventListener('click', submitBooking);

  // Handle source dropdown conditional input
  document.getElementById('q_source').addEventListener('change', (e) => {
    const otherContainer = document.getElementById('source-other-container');
    if (e.target.value === 'Other') {
      otherContainer.style.display = 'block';
    } else {
      otherContainer.style.display = 'none';
      document.getElementById('q_source_other').value = '';
    }
  });

  populateDateDropdowns();
});

async function loadCoaches() {
  try {
    const res = await fetch(`${API_BASE}/coaches`);
    const data = await res.json();
    coaches = data.coaches || [];
    renderCoaches();
  } catch (error) {
    console.error('Error loading coaches:', error);
    document.getElementById('coachSelection').innerHTML =
      '<p style="color: var(--error);">Failed to load coaches. Please refresh the page.</p>';
  }
}

function renderCoaches() {
  const container = document.getElementById('coachSelection');
  container.innerHTML = '';

  coaches.forEach(coach => {
    const card = document.createElement('div');
    card.className = 'coach-card';
    card.setAttribute('data-coach-id', coach.id);

    const photo = coach.photoUrl
      ? `<img src="${coach.photoUrl}" alt="${coach.name}" class="coach-photo" />`
      : `<div class="coach-photo-placeholder" style="background: ${coach.color};">${coach.name.charAt(0)}</div>`;

    card.innerHTML = `
      ${photo}
      <h3>${coach.name}</h3>
      ${coach.bio ? `<p class="coach-bio">${coach.bio}</p>` : ''}
      <button class="select-coach-btn" style="border-color: ${coach.color}; color: ${coach.color};">
        Select ${coach.name.split(' ')[0]}
      </button>
    `;

    card.querySelector('.select-coach-btn').addEventListener('click', () => selectCoach(coach));
    container.appendChild(card);
  });
}

function selectCoach(coach) {
  selectedCoach = coach;
  selectedSlot = null;

  // Update UI to show selection
  document.querySelectorAll('.coach-card').forEach(card => {
    card.classList.remove('selected');
  });
  document.querySelector(`[data-coach-id="${coach.id}"]`).classList.add('selected');

  // Reset week offset and load availability
  weekOffset = 0;
  loadAvailability();
}

async function loadAvailability() {
  if (!selectedCoach) {
    document.getElementById('timeSlots').innerHTML =
      '<tr><td colspan="8" style="text-align: center; padding: 40px; color: var(--muted);">Please select a coach first.</td></tr>';
    return;
  }

  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const url = `${API_BASE}/availability?coachId=${selectedCoach.id}&week=${weekOffset}&tz=${encodeURIComponent(tz)}`;

  try {
    const res = await fetch(url);
    const data = await res.json();
    renderSlots(data.slots || []);
  } catch (error) {
    console.error('Error loading availability:', error);
    document.getElementById('timeSlots').innerHTML =
      '<tr><td colspan="8" style="text-align: center; color: var(--error); padding: 40px;">Failed to load availability. Please try again.</td></tr>';
  }
}

function renderSlots(slots) {
  const tbody = document.getElementById('timeSlots');
  tbody.innerHTML = '';
  selectedSlot = null;

  if (!slots.length) {
    tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; color: var(--muted); padding: 40px;">No slots available in this window.</td></tr>';
    return;
  }

  // Set week label
  const first = new Date(Number(slots[0].start));
  const last = new Date(Number(slots[slots.length - 1].end));
  document.getElementById('weekLabel').textContent = `${first.toLocaleDateString()} – ${last.toLocaleDateString()}`;

  // Create calendar structure
  const timeSlots = {};
  const times = new Set();

  // Organize slots by day and time
  slots.forEach(s => {
    const start = new Date(Number(s.start));
    const dayOfWeek = start.getDay(); // 0=Sun, 1=Mon, etc.
    const timeStr = start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });

    if (!timeSlots[timeStr]) timeSlots[timeStr] = {};
    timeSlots[timeStr][dayOfWeek] = s;
    times.add(timeStr);
  });

  // Sort times
  const sortedTimes = Array.from(times).sort((a, b) => {
    const [aTime, aPeriod] = a.split(' ');
    const [bTime, bPeriod] = b.split(' ');
    const [aHour, aMin] = aTime.split(':').map(Number);
    const [bHour, bMin] = bTime.split(':').map(Number);

    const aHour24 = aPeriod === 'PM' && aHour !== 12 ? aHour + 12 : (aPeriod === 'AM' && aHour === 12 ? 0 : aHour);
    const bHour24 = bPeriod === 'PM' && bHour !== 12 ? bHour + 12 : (bPeriod === 'AM' && bHour === 12 ? 0 : bHour);

    return aHour24 * 60 + aMin - (bHour24 * 60 + bMin);
  });

  // Render table rows
  sortedTimes.forEach(timeStr => {
    const row = document.createElement('tr');

    // Time label cell
    const timeCell = document.createElement('td');
    timeCell.className = 'time-label';
    timeCell.textContent = timeStr;
    row.appendChild(timeCell);

    // Days of week (Mon=1, Tue=2, ..., Sun=0)
    const dayOrder = [1, 2, 3, 4, 5, 6, 0]; // Mon-Sun
    dayOrder.forEach(dayNum => {
      const slot = timeSlots[timeStr] && timeSlots[timeStr][dayNum];
      const cell = document.createElement('td');
      const slotEl = document.createElement('div');
      const isWeekend = dayNum === 6 || dayNum === 0; // Saturday or Sunday

      if (slot && !isWeekend) {
        slotEl.className = 'time-slot';
        slotEl.textContent = '●';
        slotEl.setAttribute('title', `${new Date(Number(slot.start)).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })} at ${timeStr}`);
        slotEl.style.borderColor = selectedCoach.color;
        slotEl.addEventListener('click', () => {
          document.querySelectorAll('.time-slot.selected').forEach(b => b.classList.remove('selected'));
          slotEl.classList.add('selected');
          slotEl.style.background = selectedCoach.color;
          selectedSlot = slot;
        });
      } else if (isWeekend) {
        slotEl.className = 'time-slot weekend';
        slotEl.textContent = '×';
        slotEl.setAttribute('title', 'Weekends unavailable');
      } else {
        slotEl.className = 'time-slot unavailable';
        slotEl.textContent = '—';
      }

      cell.appendChild(slotEl);
      row.appendChild(cell);
    });

    tbody.appendChild(row);
  });
}

async function submitBooking() {
  const status = document.getElementById('status');
  status.textContent = '';

  const name = document.getElementById('name').value.trim();
  const email = document.getElementById('email').value.trim();
  const phone = document.getElementById('phone').value.trim();

  // Collect form data
  const gameDate = `${document.getElementById('q_month').value}/${document.getElementById('q_day').value}/${document.getElementById('q_year').value}`;
  const sourceValue = document.getElementById('q_source').value;
  const sourceOther = document.getElementById('q_source_other').value.trim();
  const finalSource = sourceValue === 'Other' ? sourceOther : sourceValue;

  const gameDetails = {
    game: document.getElementById('q_game').value.trim(),
    date: gameDate,
    time: document.getElementById('q_time').value.trim(),
    timezone: document.getElementById('q_timezone').value,
    focus: document.getElementById('q_focus').value.trim(),
    performance: document.getElementById('q_performance').value.trim(),
    rating: parseInt(document.getElementById('q_rating').value, 10),
    events: document.getElementById('q_events').value.trim(),
    source: finalSource,
  };

  // Validation
  if (!selectedCoach) { status.textContent = 'Please select a coach.'; return; }
  if (!name || !email) { status.textContent = 'Name and email are required.'; return; }
  if (!selectedSlot) { status.textContent = 'Please select a time slot.'; return; }
  if (!gameDetails.game || !gameDetails.time || !gameDetails.focus || !gameDetails.performance || !gameDetails.rating || !gameDetails.source) {
    status.textContent = 'Please answer all required questions.';
    return;
  }
  if (sourceValue === 'Other' && !sourceOther) {
    status.textContent = 'Please specify the source when "Other" is selected.';
    return;
  }

  const clientTz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const payload = {
    coachId: selectedCoach.id,
    clientId: cid || undefined,
    clientName: name,
    clientEmail: email,
    clientPhone: phone || undefined,
    startTime: selectedSlot.start,
    endTime: selectedSlot.end,
    timezone: clientTz,
    gameDetails,
  };

  try {
    status.textContent = 'Booking...';
    const res = await fetch(`${API_BASE}/book`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    const data = await res.json();

    if (data.success) {
      status.textContent = `✓ Booked with ${selectedCoach.name}! You will receive a confirmation email.`;
      status.style.color = 'var(--success, #4FFF4F)';

      // Optionally disable form
      document.getElementById('submit').disabled = true;
    } else {
      status.textContent = 'Booking failed: ' + (data.error || 'Unknown error');
      status.style.color = 'var(--error, #C41E3A)';
    }
  } catch (error) {
    status.textContent = 'Network error. Please try again.';
    status.style.color = 'var(--error, #C41E3A)';
    console.error('Booking error:', error);
  }
}

function populateDateDropdowns() {
  const now = new Date();
  const currentMonth = now.getMonth() + 1;
  const currentDay = now.getDate();
  const currentYear = now.getFullYear();

  // Populate days (1-31)
  const daySelect = document.getElementById('q_day');
  for (let i = 1; i <= 31; i++) {
    const option = document.createElement('option');
    option.value = i;
    option.textContent = i;
    if (i === currentDay) option.selected = true;
    daySelect.appendChild(option);
  }

  // Populate years (current year - 1 to current year)
  const yearSelect = document.getElementById('q_year');
  for (let i = currentYear - 1; i <= currentYear; i++) {
    const option = document.createElement('option');
    option.value = i;
    option.textContent = i;
    if (i === currentYear) option.selected = true;
    yearSelect.appendChild(option);
  }

  // Set current month as selected
  document.getElementById('q_month').value = currentMonth;
}
