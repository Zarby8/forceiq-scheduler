import Foundation
import SwiftUI

// Configure these before building
enum AppConfig {
    // Base URL of your booking site (used only for user display) e.g. https://schedule.forcehockeyiq.com
    static let WEB_BASE = URL(string: "https://schedule.forcehockeyiq.com")!
    // Base URL of your Vercel API deployment
    static let API_BASE = URL(string: "https://schedule.forcehockeyiq.com/api")!
    // Secret shared between app and Vercel API for signing links
    static let HMAC_SECRET = "pV8DO3RPkJz/ZIWKtOCldVsgvdg9JKmbtebKzbQGYSM="
    // Apple Events permission string (Info.plist also needs NSAppleEventsUsageDescription)
    static let appleEventsPurpose = "Used to send weekly scheduling messages via Messages."
}

// Branding colors per ForceIQ
extension Color {
    static let forceBlack = Color(red: 0/255, green: 0/255, blue: 0/255)
    static let forceIceCharcoal = Color(red: 10/255, green: 10/255, blue: 10/255)
    static let forceCard = Color(red: 26/255, green: 26/255, blue: 26/255)
    static let forceYellow = Color(red: 244/255, green: 196/255, blue: 48/255)
    static let forceGreen = Color(red: 79/255, green: 255/255, blue: 79/255)
    static let forceRed = Color(red: 196/255, green: 30/255, blue: 58/255)
}

