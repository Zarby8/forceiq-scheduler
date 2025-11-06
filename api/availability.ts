// GET /api/availability?coachId={id}&week={offset}&tz={timezone}
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getCoaches, getAvailableSlots } from './_lib/google-calendar';
import type { AvailabilityResponse } from '../shared/types';

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { coachId, week, tz } = req.query;

    if (!coachId || typeof coachId !== 'string') {
      return res.status(400).json({ error: 'coachId is required' });
    }

    const coaches = getCoaches();
    const coach = coaches.find(c => c.id === coachId);

    if (!coach) {
      return res.status(404).json({ error: 'Coach not found' });
    }

    const weekOffset = week ? parseInt(week as string, 10) : 0;
    const timezone = (tz as string) || process.env.TIMEZONE || 'America/Detroit';

    const slots = await getAvailableSlots(coach, weekOffset, timezone);

    const response: AvailabilityResponse = {
      coach: {
        id: coach.id,
        name: coach.name,
      },
      slots,
    };

    return res.status(200).json(response);
  } catch (error: any) {
    console.error('Error fetching availability:', error);
    return res.status(500).json({ error: 'Failed to fetch availability' });
  }
}
