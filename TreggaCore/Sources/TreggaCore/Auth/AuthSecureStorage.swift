import Foundation
import Security

/// Storage seguro de tokens de auth (spec §6).
/// Producción: KeychainAuthStorage (SecItem nativo).
/// Tests: MockAuthStorage in-memory.
public protocol AuthSecureStorage: Sendable {
    func set(_ value: String, forKey key: String) async throws
    func get(key: String) async throws -> String?
    func delete(key: String) async throws
}

public enum AuthStorageError: Error, Equatable, Sendable {
    case osStatus(OSStatus)
    case encodingFailure
}

/// Implementación de producción usando Keychain nativo (SecItem*).
/// Service prefix: "tregga.delivery".
public final class KeychainAuthStorage: AuthSecureStorage, @unchecked Sendable {
    private let service = "tregga.delivery"

    public init() {}

    public func set(_ value: String, forKey key: String) async throws {
        guard let data = value.data(using: .utf8) else {
            throw AuthStorageError.encodingFailure
        }
        try await delete(key: key)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw AuthStorageError.osStatus(status) }
    }

    public func get(key: String) async throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else {
            throw AuthStorageError.osStatus(status)
        }
        return str
    }

    public func delete(key: String) async throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AuthStorageError.osStatus(status)
        }
    }
}

/// Mock in-memory para tests.
@MainActor
public final class MockAuthStorage: AuthSecureStorage {
    private var data: [String: String] = [:]
    public init() {}

    public func set(_ value: String, forKey key: String) async throws {
        data[key] = value
    }
    public func get(key: String) async throws -> String? {
        data[key]
    }
    public func delete(key: String) async throws {
        data.removeValue(forKey: key)
    }
}

/// Keys estándar del storage para Tregga Delivery.
public enum AuthStorageKey {
    public static let refreshToken = "refresh_token"
    public static let accessToken  = "access_token"
    public static let userId       = "user_id"
    /// Epoch (segundos) de la última actividad. Base de la ventana deslizante de
    /// 30 días: si se excede sin abrir la app, la sesión se cierra en `restore()`.
    public static let lastActiveAt = "last_active_at"
}
