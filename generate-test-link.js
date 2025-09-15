const crypto = require('crypto');

const HMAC_SECRET = 'pV8DO3RPkJz/ZIWKtOCldVsgvdg9JKmbtebKzbQGYSM=';
const WEB_BASE = 'https://schedule.forcehockeyiq.com';

function generateBookingLink(clientId, name = '', email = '') {
  const timestamp = Math.floor(Date.now() / 1000);
  const raw = `${clientId}|${timestamp}`;

  const hmac = crypto.createHmac('sha256', Buffer.from(HMAC_SECRET, 'base64'));
  hmac.update(raw);
  const signature = hmac.digest('base64url');

  const params = new URLSearchParams({
    cid: clientId,
    ts: timestamp.toString(),
    sig: signature
  });

  if (name) params.set('name', name);
  if (email) params.set('email', email);

  return `${WEB_BASE}?${params.toString()}`;
}

// Generate test link
const testLink = generateBookingLink('TEST_CLIENT_001', 'John Doe', 'john@example.com');
console.log('Test booking link:');
console.log(testLink);