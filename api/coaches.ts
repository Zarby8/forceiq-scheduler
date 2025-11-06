// GET /api/coaches - List available coaches
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getCoaches } from './_lib/google-calendar';
import type { CoachesResponse } from '../shared/types';

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
    const coaches = getCoaches();

    const response: CoachesResponse = {
      coaches: coaches.map(coach => ({
        id: coach.id,
        name: coach.name,
        photoUrl: coach.photoUrl,
        bio: coach.bio,
        color: coach.color,
      })),
    };

    return res.status(200).json(response);
  } catch (error: any) {
    console.error('Error fetching coaches:', error);
    return res.status(500).json({ error: 'Failed to fetch coaches' });
  }
}
