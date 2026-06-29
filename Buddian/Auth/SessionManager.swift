import Foundation
import Security

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var isAuthenticated = false

    private let sessionTokenKey = "com.buddian.session_token"
    private let userUIDKey = "com.buddian.user_uid"
    private let userEmailKey = "com.buddian.user_email"

    var sessionToken: String? {
        loadFromKeychain(account: sessionTokenKey)
    }

    var userUID: String? {
        UserDefaults.standard.string(forKey: userUIDKey)
    }

    var userEmail: String? {
        UserDefaults.standard.string(forKey: userEmailKey)
    }

    private init() {
        isAuthenticated = sessionToken != nil
    }

    func saveSession(token: String, uid: String, email: String?) {
        saveToKeychain(account: sessionTokenKey, data: token)
        UserDefaults.standard.set(uid, forKey: userUIDKey)
        if let email {
            UserDefaults.standard.set(email, forKey: userEmailKey)
        }
        isAuthenticated = true
    }

    func clearSession() {
        deleteFromKeychain(account: sessionTokenKey)
        UserDefaults.standard.removeObject(forKey: userUIDKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        isAuthenticated = false
    }

    // MARK: - Keychain

    private func saveToKeychain(account: String, data: String) {
        deleteFromKeychain(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.buddian",
            kSecAttrAccount as String: account,
            kSecValueData as String: data.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.buddian",
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.buddian",
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
