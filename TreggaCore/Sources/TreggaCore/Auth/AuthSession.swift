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

    /// Ventana deslizante de inactividad: la sesión se cierra tras 30 días SIN abrir
    /// la app. Cada `restore()` (abrir) y `persist()` (login/refresh) renueva la
    /// ventana; un usuario activo nunca se desloguea solo.
    private static let maxInactivity: TimeInterval = 30 * 24 * 60 * 60

    public init(storage: AuthSecureStorage) {
        self.storage = storage
    }

    public func restore() async {
        do {
            let access = try await storage.get(key: AuthStorageKey.accessToken)
            let refresh = try await storage.get(key: AuthStorageKey.refreshToken)
            let userIdStr = try await storage.get(key: AuthStorageKey.userId)
            guard let access, let refresh, let userIdStr, let userId = UUID(uuidString: userIdStr) else {
                self.tokens = nil
                return
            }
            // Si pasaron más de 30 días sin abrir la app, cerrar la sesión. Las
            // sesiones previas a este cambio no tienen marca → no expiran de golpe;
            // se les fija la ventana ahora (restaurar = actividad → renueva).
            let lastActive = try await storage.get(key: AuthStorageKey.lastActiveAt)
            if let lastActive, let ts = TimeInterval(lastActive),
               Date().timeIntervalSince1970 - ts > Self.maxInactivity {
                await clear()
                return
            }
            self.tokens = Tokens(accessToken: access, refreshToken: refresh, userId: userId)
            try? await storage.set(String(Date().timeIntervalSince1970), forKey: AuthStorageKey.lastActiveAt)
        } catch {
            self.tokens = nil
        }
    }

    public func persist(_ newTokens: Tokens) async {
        self.tokens = newTokens
        try? await storage.set(newTokens.accessToken, forKey: AuthStorageKey.accessToken)
        try? await storage.set(newTokens.refreshToken, forKey: AuthStorageKey.refreshToken)
        try? await storage.set(newTokens.userId.uuidString, forKey: AuthStorageKey.userId)
        try? await storage.set(String(Date().timeIntervalSince1970), forKey: AuthStorageKey.lastActiveAt)
    }

    public func clear() async {
        self.tokens = nil
        try? await storage.delete(key: AuthStorageKey.accessToken)
        try? await storage.delete(key: AuthStorageKey.refreshToken)
        try? await storage.delete(key: AuthStorageKey.userId)
        try? await storage.delete(key: AuthStorageKey.lastActiveAt)
    }
}
