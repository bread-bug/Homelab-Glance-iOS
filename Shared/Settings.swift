import Observation
import Foundation
import Security

/// Server address lives in defaults; the key lives in the keychain.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    /// Shared with the share extension; both targets carry this app group.
    static let appGroup = "group.dev.breadbug.HomelabGlance"

    private static let urlKey = "baseURL"
    private static let keychainAccount = "api-key"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    var baseURL: String {
        didSet { Self.defaults.set(baseURL, forKey: Self.urlKey) }
    }

    var apiKey: String {
        didSet { Keychain.set(apiKey, account: Self.keychainAccount) }
    }

    var isConfigured: Bool { !baseURL.isEmpty && !apiKey.isEmpty }

    private init() {
        // migrate anything written before the group existed
        let legacyURL = UserDefaults.standard.string(forKey: Self.urlKey)
        baseURL = Self.defaults.string(forKey: Self.urlKey) ?? legacyURL ?? ""
        apiKey = Keychain.get(account: Self.keychainAccount) ?? ""

        if Self.defaults.string(forKey: Self.urlKey) == nil, let legacyURL {
            Self.defaults.set(legacyURL, forKey: Self.urlKey)
        }
    }

    var client: APIClient { APIClient(baseURL: baseURL, apiKey: apiKey) }
}

enum Keychain {
    private static let service = "dev.breadbug.HomelabGlance"
    private static let accessGroup = AppSettings.appGroup

    static func set(_ value: String, account: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        query[kSecAttrAccessGroup as String] = accessGroup
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessGroup as String] = accessGroup
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(account: String) -> String? {
        if let shared = read(account: account, group: accessGroup) { return shared }
        // written before the app group existed: migrate it across
        guard let legacy = read(account: account, group: nil) else { return nil }
        set(legacy, account: account)
        return legacy
    }

    private static func read(account: String, group: String?) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        if let group { query[kSecAttrAccessGroup as String] = group }

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
