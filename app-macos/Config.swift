import Foundation
import SwiftUI

// Configure these before building
enum AppConfig {
    // Base URL of your booking site (used only for user display) e.g. https://schedule.forcehockeyiq.com
    static let WEB_BASE = URL(string: "https://schedule.forcehockeyiq.com")!
    // Base URL of your Apps Script deployment (ends with /exec)
    static let GAS_BASE = URL(string: "https://script.google.com/macros/s/AKfycbwYYyVTh_5voqqPHMm8mQf4S23LS9LFv-P6bALnKBkid5x0o5g5yNLMpOACfSpi4pXGFA/exec")!
    // Secret shared between app and Apps Script for signing links
    static let HMAC_SECRET = "CHANGE_ME_TO_RANDOM_32+_CHARS"
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

