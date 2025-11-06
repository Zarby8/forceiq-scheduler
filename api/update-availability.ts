// POST /api/update-availability - Update coach availability in KV storage

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { kv } from '@vercel/kv';
import type { WeeklySchedule } from '../shared/types';

interface UpdateAvailabilityRequest {
  coachId: string;
  weeklyHours: WeeklySchedule;
  adminToken?: string; // Optional auth token for security
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { coachId, weeklyHours, adminToken } = req.body as UpdateAvailabilityRequest;

    // Validate input
    if (!coachId || !weeklyHours) {
      return res.status(400).json({ error: 'Missing coachId or weeklyHours' });
    }

    // Optional: Verify admin token for security
    const expectedToken = process.env.ADMIN_TOKEN;
    if (expectedToken && adminToken !== expectedToken) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Store in KV with key: availability:{coachId}
    const kvKey = `availability:${coachId}`;
    await kv.set(kvKey, weeklyHours);

    console.log(`✅ Updated availability for coach: ${coachId}`);

    return res.status(200).json({
      success: true,
      coachId,
      message: 'Availability updated successfully'
    });
  } catch (error) {
    console.error('❌ Error updating availability:', error);
    return res.status(500).json({
      error: 'Failed to update availability',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
