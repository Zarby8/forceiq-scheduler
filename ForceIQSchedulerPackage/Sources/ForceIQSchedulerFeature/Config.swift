import Foundation
import SwiftUI
import Security

public class AppConfig: ObservableObject {
    @Published public var webBase: String = "https://schedule.forcehockeyiq.com"
    @Published public var gasBase: String = "https://script.google.com/macros/s/AKfycbwYYyVTh_5voqqPHMm8mQf4S23LS9LFv-P6bALnKBkid5x0o5g5yNLMpOACfSpi4pXGFA/exec"
    @Published public var hmacSecret: String = ""
    @Published public var googleAccessToken: String = ""
    @Published public var googleRefreshToken: String = ""
    @Published public var googleAccountEmail: String = ""
    @Published public var isGoogleAuthenticated: Bool = false

    private let webBaseKey = "ForceIQ.WebBase"
    private let gasBaseKey = "ForceIQ.GasBase"
    private let hmacSecretKey = "ForceIQ.HmacSecret"
    private let googleAccessTokenKey = "ForceIQ.GoogleAccessToken"
    private let googleRefreshTokenKey = "ForceIQ.GoogleRefreshToken"
    private let googleAccountEmailKey = "ForceIQ.GoogleAccountEmail"

    public init() {
        loadSettings()
    }

    private func loadSettings() {
        webBase = UserDefaults.standard.string(forKey: webBaseKey) ?? webBase
        gasBase = UserDefaults.standard.string(forKey: gasBaseKey) ?? gasBase
        hmacSecret = loadFromKeychain(key: hmacSecretKey) ?? generateRandomSecret()
        googleAccessToken = loadFromKeychain(key: googleAccessTokenKey) ?? ""
        googleRefreshToken = loadFromKeychain(key: googleRefreshTokenKey) ?? ""
        googleAccountEmail = UserDefaults.standard.string(forKey: googleAccountEmailKey) ?? ""
        isGoogleAuthenticated = !googleAccessToken.isEmpty && !googleAccountEmail.isEmpty
    }

    public func saveSettings() {
        UserDefaults.standard.set(webBase, forKey: webBaseKey)
        UserDefaults.standard.set(gasBase, forKey: gasBaseKey)
        UserDefaults.standard.set(googleAccountEmail, forKey: googleAccountEmailKey)
        saveToKeychain(key: hmacSecretKey, value: hmacSecret)
        saveToKeychain(key: googleAccessTokenKey, value: googleAccessToken)
        saveToKeychain(key: googleRefreshTokenKey, value: googleRefreshToken)
        isGoogleAuthenticated = !googleAccessToken.isEmpty && !googleAccountEmail.isEmpty
    }

    public func signOutFromGoogle() {
        googleAccessToken = ""
        googleRefreshToken = ""
        googleAccountEmail = ""
        isGoogleAuthenticated = false
        UserDefaults.standard.removeObject(forKey: googleAccountEmailKey)
        deleteFromKeychain(key: googleAccessTokenKey)
        deleteFromKeychain(key: googleRefreshTokenKey)
    }

    public var webBaseURL: URL {
        return URL(string: webBase) ?? URL(string: "https://schedule.forcehockeyiq.com")!
    }

    public var gasBaseURL: URL {
        return URL(string: gasBase) ?? URL(string: "https://script.google.com/macros/s/AKfycbwYYyVTh_5voqqPHMm8mQf4S23LS9LFv-P6bALnKBkid5x0o5g5yNLMpOACfSpi4pXGFA/exec")!
    }

    private func generateRandomSecret() -> String {
        let length = 32
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// Branding colors per ForceIQ
public extension Color {
    static let forceBlack = Color(red: 0/255, green: 0/255, blue: 0/255)
    static let forceIceCharcoal = Color(red: 10/255, green: 10/255, blue: 10/255)
    static let forceCard = Color(red: 26/255, green: 26/255, blue: 26/255)
    static let forceYellow = Color(red: 244/255, green: 196/255, blue: 48/255)
    static let forceGreen = Color(red: 79/255, green: 255/255, blue: 79/255)
    static let forceRed = Color(red: 196/255, green: 30/255, blue: 58/255)
    static let forceBlue = Color(red: 51/255, green: 153/255, blue: 255/255)
}