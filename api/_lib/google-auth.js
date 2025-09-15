import { SignJWT, importPKCS8 } from 'jose'

/**
 * Create a JWT token for Google Service Account authentication
 * Works in Vercel Edge Runtime
 */
export async function createGoogleJWT() {
  const serviceAccountEmail = process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL
  const privateKeyPem = process.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY

  if (!serviceAccountEmail || !privateKeyPem) {
    throw new Error('Missing Google Service Account credentials')
  }

  // Clean and import the private key
  const cleanKey = privateKeyPem.replace(/\\n/g, '\n')
  const privateKey = await importPKCS8(cleanKey, 'RS256')

  const now = Math.floor(Date.now() / 1000)

  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/spreadsheets'
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(serviceAccountEmail)
    .setSubject(serviceAccountEmail)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600) // 1 hour
    .setNotBefore(now)
    .sign(privateKey)

  return jwt
}

/**
 * Get Google access token using Service Account JWT
 */
export async function getGoogleAccessToken() {
  const jwt = await createGoogleJWT()

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Failed to get access token: ${error}`)
  }

  const data = await response.json()
  return data.access_token
}

/**
 * Make authenticated request to Google Calendar API
 */
export async function googleCalendarRequest(endpoint, options = {}) {
  const accessToken = await getGoogleAccessToken()

  const response = await fetch(`https://www.googleapis.com/calendar/v3${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      ...options.headers
    }
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Google Calendar API error: ${error}`)
  }

  return response.json()
}

/**
 * Make authenticated request to Google Sheets API
 */
export async function googleSheetsRequest(endpoint, options = {}) {
  const accessToken = await getGoogleAccessToken()

  const response = await fetch(`https://sheets.googleapis.com/v4${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      ...options.headers
    }
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Google Sheets API error: ${error}`)
  }

  return response.json()
}