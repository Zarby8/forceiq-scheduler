// POST /api/update-availability - Availability must be set via Vercel environment variables

import type { VercelRequest, VercelResponse } from '@vercel/node';
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

    // Availability is now stored in Vercel environment variables
    // Format the JSON for the user to paste into Vercel
    const envVarName = coachId === 'coach1' ? 'COACH_1_WEEKLY_HOURS' : 'COACH_2_WEEKLY_HOURS';
    const jsonValue = JSON.stringify(weeklyHours);

    console.log(`📋 Availability update requested for ${coachId}`);
    console.log(`Set this in Vercel Dashboard → Settings → Environment Variables:`);
    console.log(`${envVarName}=${jsonValue}`);

    return res.status(200).json({
      success: true,
      coachId,
      message: 'To apply this availability, set the following environment variable in Vercel Dashboard',
      instructions: {
        location: 'Vercel Dashboard → Settings → Environment Variables',
        variable: envVarName,
        value: jsonValue,
        note: 'After setting, redeploy for changes to take effect'
      }
    });
  } catch (error) {
    console.error('❌ Error updating availability:', error);
    return res.status(500).json({
      error: 'Failed to update availability',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
