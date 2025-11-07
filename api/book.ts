// POST /api/book - Create a booking
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getCoaches, createBooking } from './_lib/google-calendar';
import type { BookingRequest, BookingResponse } from '../shared/types';

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const request: BookingRequest = req.body;

    // Validate required fields
    if (!request.coachId) {
      return res.status(400).json({ error: 'coachId is required' });
    }
    if (!request.clientName || !request.clientEmail) {
      return res.status(400).json({ error: 'Client name and email are required' });
    }
    if (!request.startTime || !request.endTime) {
      return res.status(400).json({ error: 'Start and end time are required' });
    }
    if (!request.gameDetails) {
      return res.status(400).json({ error: 'Game details are required' });
    }

    // Validate game details
    const { game, focus, performance, rating } = request.gameDetails;
    if (!game || !focus || !performance || !rating) {
      return res.status(400).json({
        error: 'All game details are required (game, focus, performance, rating)'
      });
    }

    const coaches = await getCoaches();
    const coach = coaches.find(c => c.id === request.coachId);

    if (!coach) {
      return res.status(404).json({ error: 'Coach not found' });
    }

    // Verify slot is in the future
    if (request.startTime < Date.now()) {
      return res.status(400).json({ error: 'Cannot book slots in the past' });
    }

    // Create the booking
    const result = await createBooking(coach, {
      clientName: request.clientName,
      clientEmail: request.clientEmail,
      clientPhone: request.clientPhone,
      startTime: request.startTime,
      endTime: request.endTime,
      timezone: request.timezone || process.env.TIMEZONE || 'America/Detroit',
      gameDetails: request.gameDetails,
    });

    const response: BookingResponse = {
      success: true,
      eventId: result.eventId || undefined,
      calendarLink: result.calendarLink || undefined,
    };

    return res.status(200).json(response);
  } catch (error: any) {
    console.error('Error creating booking:', error);

    const response: BookingResponse = {
      success: false,
      error: error.message || 'Failed to create booking',
    };

    return res.status(500).json(response);
  }
}
