import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.forcehockeyiq.scheduler"
    private let adminTokenKey = "adminToken"

    private init() {}

    func saveAdminToken(_ token: String) {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: adminTokenKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getAdminToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: adminTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let token = String(data: data, encoding: .utf8) {
                return token
            }
        }

        return nil
    }

    func deleteAdminToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: adminTokenKey
        ]

        SecItemDelete(query as CFDictionary)
    }
}
