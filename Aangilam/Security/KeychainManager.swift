import Foundation
import Security

struct KeychainManager: SecretStoring {
    static let service = "com.aangilam.app"
    static let account = "google-cloud-translation-api-key"

    private static let lock = NSLock()
    private static var cached: String??

    func save(_ secret: String) throws {
        try delete()
        let data = Data(secret.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
        Self.lock.lock()
        Self.cached = secret
        Self.lock.unlock()
    }

    func read() -> String? {
        Self.lock.lock()
        if let cached = Self.cached {
            Self.lock.unlock()
            return cached
        }
        Self.lock.unlock()

        let value = readFromKeychain()

        Self.lock.lock()
        Self.cached = value
        Self.lock.unlock()
        return value
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
        Self.lock.lock()
        Self.cached = .some(nil)
        Self.lock.unlock()
    }

    func hasSecret() -> Bool {
        !(read() ?? "").isEmpty
    }

    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

enum KeychainError: Error {
    case unhandled(OSStatus)
}

final class InMemorySecretStore: SecretStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?

    func save(_ secret: String) throws {
        lock.lock()
        value = secret
        lock.unlock()
    }

    func read() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func delete() throws {
        lock.lock()
        value = nil
        lock.unlock()
    }

    func hasSecret() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return !(value ?? "").isEmpty
    }
}
