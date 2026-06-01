import Foundation
import Observation

/// Estado global de sesión auth. Inyectada en root de la app.
@MainActor
@Observable
public final class AuthSession {
    public struct Tokens: Codable, Equatable, Sendable {
        public let accessToken: String
        public let refreshToken: String
        public let userId: UUID

        public init(accessToken: String, refreshToken: String, userId: UUID) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.userId = userId
        }
    }

    public private(set) var tokens: Tokens?
    public var isAuthenticated: Bool { tokens != nil }

    private let storage: AuthSecureStorage

    public init(storage: AuthSecureStorage) {
        self.storage = storage
    }

    public func restore() async {
        do {
            let access = try await storage.get(key: AuthStorageKey.accessToken)
            let refresh = try await storage.get(key: AuthStorageKey.refreshToken)
            let userIdStr = try await storage.get(key: AuthStorageKey.userId)
            if let access, let refresh, let userIdStr, let userId = UUID(uuidString: userIdStr) {
                self.tokens = Tokens(accessToken: access, refreshToken: refresh, userId: userId)
            }
        } catch {
            self.tokens = nil
        }
    }

    public func persist(_ newTokens: Tokens) async {
        self.tokens = newTokens
        try? await storage.set(newTokens.accessToken, forKey: AuthStorageKey.accessToken)
        try? await storage.set(newTokens.refreshToken, forKey: AuthStorageKey.refreshToken)
        try? await storage.set(newTokens.userId.uuidString, forKey: AuthStorageKey.userId)
    }

    public func clear() async {
        self.tokens = nil
        try? await storage.delete(key: AuthStorageKey.accessToken)
        try? await storage.delete(key: AuthStorageKey.refreshToken)
        try? await storage.delete(key: AuthStorageKey.userId)
    }
}
