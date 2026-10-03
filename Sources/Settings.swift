import Observation
import Foundation
import Security

/// Server address lives in defaults; the key lives in the keychain.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private static let urlKey = "baseURL"
    private static let keychainAccount = "api-key"

    var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: Self.urlKey) }
    }

    var apiKey: String {
        didSet { Keychain.set(apiKey, account: Self.keychainAccount) }
    }

    var isConfigured: Bool { !baseURL.isEmpty && !apiKey.isEmpty }

    private init() {
        baseURL = UserDefaults.standard.string(forKey: Self.urlKey) ?? ""
        apiKey = Keychain.get(account: Self.keychainAccount) ?? ""
    }

    var client: APIClient { APIClient(baseURL: baseURL, apiKey: apiKey) }
}

enum Keychain {
    private static let service = "dev.breadbug.HomelabGlance"

    static func set(_ value: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
