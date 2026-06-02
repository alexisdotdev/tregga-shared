import Foundation

/// "Usuario recordado" para el re-login biométrico (pantalla de bienvenida estilo
/// Banamex que aparece cuando la sesión se cerró o venció).
///
/// El **nombre** se guarda en UserDefaults: no es sensible y se usa para pintar la
/// pantalla de bienvenida SIN pedir biometría. El **refresh token** va en Keychain
/// y solo debe leerse tras pasar Face ID en la capa de la app (vía
/// `BiometricAuthService`), igual que el candado de sesión activa.
@MainActor
public final class RememberedUserStore {
    private let storage: AuthSecureStorage
    private let defaults: UserDefaults
    private let tokenKey = "remembered_refresh_token"
    private let nameKey = "tregga.rememberedUser.name"
    private let userIdKey = "tregga.rememberedUser.userId"

    public init(storage: AuthSecureStorage = KeychainAuthStorage(), defaults: UserDefaults = .standard) {
        self.storage = storage
        self.defaults = defaults
    }

    /// Nombre para mostrar en la pantalla de bienvenida (no requiere biometría).
    public var displayName: String? { defaults.string(forKey: nameKey) }

    public var userId: UUID? {
        defaults.string(forKey: userIdKey).flatMap(UUID.init(uuidString:))
    }

    /// Hay un usuario recordado disponible para re-login biométrico.
    public var hasRemembered: Bool { displayName != nil && userId != nil }

    public func save(displayName: String, refreshToken: String, userId: UUID) async {
        defaults.set(displayName, forKey: nameKey)
        defaults.set(userId.uuidString, forKey: userIdKey)
        try? await storage.set(refreshToken, forKey: tokenKey)
    }

    /// Lee el refresh token guardado. La app debe haber pasado Face ID antes.
    public func refreshToken() async -> String? {
        (try? await storage.get(key: tokenKey)) ?? nil
    }

    public func clear() async {
        defaults.removeObject(forKey: nameKey)
        defaults.removeObject(forKey: userIdKey)
        try? await storage.delete(key: tokenKey)
    }
}
