// Shared TypeScript types for ForceIQ Scheduler

export interface Coach {
  id: string;
  name: string;
  email: string;
  calendarId: string;
  photoUrl?: string;
  bio?: string;
  weeklyHours: WeeklySchedule;
  color: string;
}

export interface WeeklySchedule {
  0: TimeWindow[];  // Sunday
  1: TimeWindow[];  // Monday
  2: TimeWindow[];  // Tuesday
  3: TimeWindow[];  // Wednesday
  4: TimeWindow[];  // Thursday
  5: TimeWindow[];  // Friday
  6: TimeWindow[];  // Saturday
}

export interface TimeWindow {
  start: string;  // "10:00"
  end: string;    // "14:00"
}

export interface Client {
  id: string;
  name: string;
  phone: string;
  email: string;
  preferredCoach?: string;
  createdAt: Date;
  lastMessageSent?: Date;
}

export interface TimeSlot {
  start: number;      // Unix timestamp in ms
  end: number;        // Unix timestamp in ms
  available: boolean;
}

export interface AvailabilityRequest {
  coachId: string;
  week?: number;      // Week offset (0 = this week, 1 = next week)
  tz?: string;        // Client timezone
}

export interface AvailabilityResponse {
  coach: {
    id: string;
    name: string;
  };
  slots: TimeSlot[];
}

export interface GameDetails {
  game: string;
  date: string;
  time: string;
  timezone: string;
  focus: string;
  performance: string;
  rating: number;
  events?: string;
  source: string;
}

export interface BookingRequest {
  coachId: string;
  clientId?: string;
  clientName: string;
  clientEmail: string;
  clientPhone?: string;
  startTime: number;
  endTime: number;
  timezone: string;
  gameDetails: GameDetails;
}

export interface BookingResponse {
  success: boolean;
  eventId?: string;
  calendarLink?: string;
  error?: string;
}

export interface CoachesResponse {
  coaches: Array<{
    id: string;
    name: string;
    photoUrl?: string;
    bio?: string;
    color: string;
  }>;
}
