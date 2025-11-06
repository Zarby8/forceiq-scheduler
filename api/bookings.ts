// GET /api/bookings - Fetch upcoming bookings from all coaches' calendars

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getCoaches, getUpcomingBookings } from './_lib/google-calendar';

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Optional: Verify admin token for security
    const authHeader = req.headers.authorization;
    const expectedToken = process.env.ADMIN_TOKEN;

    if (expectedToken) {
      const providedToken = authHeader?.replace('Bearer ', '');
      if (providedToken !== expectedToken) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
    }

    const coaches = await getCoaches();
    const bookings = await getUpcomingBookings(coaches);

    return res.status(200).json({
      success: true,
      bookings,
      count: bookings.length
    });
  } catch (error) {
    console.error('❌ Error fetching bookings:', error);
    return res.status(500).json({
      error: 'Failed to fetch bookings',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
