import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
public class GoogleOAuthManager: NSObject, ObservableObject {
    @Published public var isAuthenticated = false
    @Published public var userEmail = ""
    @Published public var isLoading = false
    @Published public var errorMessage = ""

    private var accessToken = ""
    private var refreshToken = ""
    private var webAuthSession: ASWebAuthenticationSession?

    // Google OAuth Configuration - Replace with your actual client ID
    private let clientId = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    private let clientSecret = "YOUR_GOOGLE_CLIENT_SECRET"
    private let redirectURI = "com.forcehockeyiq.scheduler://oauth"
    private let scope = "https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/userinfo.email"

    public override init() {
        super.init()
        loadStoredCredentials()
    }

    public func signIn() {
        isLoading = true
        errorMessage = ""

        let authURL = buildAuthURL()

        webAuthSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "com.forcehockeyiq.scheduler") { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.handleAuthCallback(callbackURL: callbackURL, error: error)
            }
        }

        webAuthSession?.presentationContextProvider = self
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        webAuthSession?.start()
    }

    public func signOut() {
        accessToken = ""
        refreshToken = ""
        userEmail = ""
        isAuthenticated = false
        clearStoredCredentials()
    }

    private func buildAuthURL() -> URL {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components.url!
    }

    private func handleAuthCallback(callbackURL: URL?, error: Error?) {
        isLoading = false

        if let error = error {
            if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
            return
        }

        guard let callbackURL = callbackURL,
              let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            errorMessage = "Failed to get authorization code"
            return
        }

        exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) {
        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI
        ]

        let postData = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = postData.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleTokenResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func handleTokenResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            errorMessage = "Token exchange failed: \(error.localizedDescription)"
            return
        }

        guard let data = data else {
            errorMessage = "No data received from token exchange"
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let accessToken = json?["access_token"] as? String {
                self.accessToken = accessToken
                self.refreshToken = json?["refresh_token"] as? String ?? ""

                // Get user info
                fetchUserInfo()
            } else if let errorDesc = json?["error_description"] as? String {
                errorMessage = errorDesc
            } else {
                errorMessage = "Failed to parse token response"
            }
        } catch {
            errorMessage = "Failed to parse token response: \(error.localizedDescription)"
        }
    }

    private func fetchUserInfo() {
        let userInfoURL = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: userInfoURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleUserInfoResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func handleUserInfoResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            errorMessage = "Failed to get user info: \(error.localizedDescription)"
            return
        }

        guard let data = data else {
            errorMessage = "No user info data received"
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let email = json?["email"] as? String {
                userEmail = email
                isAuthenticated = true
                storeCredentials()
            } else {
                errorMessage = "Failed to get user email"
            }
        } catch {
            errorMessage = "Failed to parse user info: \(error.localizedDescription)"
        }
    }

    public func refreshAccessToken() async -> Bool {
        guard !refreshToken.isEmpty else { return false }

        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]

        let postData = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = postData.data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let newAccessToken = json?["access_token"] as? String {
                accessToken = newAccessToken
                storeCredentials()
                return true
            }
        } catch {
            print("Failed to refresh token: \(error)")
        }

        return false
    }

    private func storeCredentials() {
        let keychain = KeychainHelper()
        keychain.save(accessToken, forKey: "GoogleAccessToken")
        keychain.save(refreshToken, forKey: "GoogleRefreshToken")
        keychain.save(userEmail, forKey: "GoogleUserEmail")
    }

    private func loadStoredCredentials() {
        let keychain = KeychainHelper()
        accessToken = keychain.load(forKey: "GoogleAccessToken") ?? ""
        refreshToken = keychain.load(forKey: "GoogleRefreshToken") ?? ""
        userEmail = keychain.load(forKey: "GoogleUserEmail") ?? ""
        isAuthenticated = !accessToken.isEmpty && !userEmail.isEmpty
    }

    private func clearStoredCredentials() {
        let keychain = KeychainHelper()
        keychain.delete(forKey: "GoogleAccessToken")
        keychain.delete(forKey: "GoogleRefreshToken")
        keychain.delete(forKey: "GoogleUserEmail")
    }

    public func getAccessToken() -> String {
        return accessToken
    }
}

extension GoogleOAuthManager: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// Helper class for Keychain operations
class KeychainHelper {
    func save(_ data: String, forKey key: String) {
        let data = Data(data.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}