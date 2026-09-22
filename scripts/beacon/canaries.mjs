// Synthetic capture canaries. These are not clients, bookings, or secrets.
export const CANARY_SECRET = "HMAC_SECRET=abcdefghijklmnop";
export const CANARY_CLIENT = "client: Pat Example";
export const CANARY_SLOT = "slot: 2026-09-22T17:00:00-04:00";
export const CANARY_EMAIL = "pat.example@example.com";

export const SENSITIVE_PROMPT = [
  CANARY_CLIENT,
  CANARY_SLOT,
  CANARY_EMAIL,
  CANARY_SECRET,
  "bearer sk-abcdefghijklmnopqrstuvwxyz",
].join(" ");

export function residue(text) {
  const blob = String(text);
  return (
    blob.includes("abcdefghijklmnop") ||
    blob.includes("Pat Example") ||
    blob.includes("pat.example@example.com") ||
    blob.includes("sk-abcdefghijklmnopqrstuvwxyz") ||
    blob.includes("2026-09-22T17:00:00-04:00")
  );
}
