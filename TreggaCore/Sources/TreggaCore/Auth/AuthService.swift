import Foundation

/// Closure que la View pasa a `signInWithGoogle` para abrir el flujo OAuth.
/// La View típicamente usa `@Environment(\.webAuthenticationSession)` para
/// invocar `authenticate(using:callbackURLScheme:)` y devolver la callback URL.
public typealias OAuthLaunchFlow = @MainActor @Sendable (_ url: URL) async throws -> URL

/// Servicio de autenticación (envuelve supabase-swift en impl real).
/// En este plan solo existe el Mock — la impl Supabase llega cuando se integre la lib.
public protocol AuthService: Sendable {
    func sendOTP(phoneE164: String) async throws
    func verifyOTP(phoneE164: String, code: String) async throws -> AuthSession.Tokens
    func currentSession() async throws -> AuthSession.Tokens?
    func signOut() async throws

    /// Cierra la sesión SOLO localmente, **sin revocar** el refresh token en el
    /// servidor, para permitir un re-login biométrico posterior con
    /// `restoreSession`. Se usa al "cerrar sesión" cuando Face ID está activado.
    func signOutLocal() async throws

    /// Re-establece la sesión a partir de un refresh token guardado (re-login
    /// biométrico estilo Banamex). Devuelve tokens frescos. Lanza si el token
    /// expiró o fue revocado — en ese caso la app cae al login normal.
    func restoreSession(refreshToken: String) async throws -> AuthSession.Tokens

    /// `true` si la sesión activa es anónima (andamiaje del signup, no un login
    /// real). Se usa al arrancar para no resumir un signup abandonado.
    func currentUserIsAnonymous() async -> Bool

    /// Convierte la cuenta actual (anónima del signup) en una cuenta real con
    /// email+contraseña, para que el repartidor pueda volver a iniciar sesión.
    func registerEmailPassword(email: String, password: String) async throws

    /// Verifica si un teléfono ya tiene una cuenta de repartidor.
    /// (Compat — internamente espejea `phoneAccountKind == .repartidor`.)
    func phoneIsRegistered(phoneE164: String) async throws -> Bool

    /// Verifica si un correo ya tiene una cuenta de repartidor.
    /// (Compat — internamente espejea `emailAccountKind == .repartidor`.)
    func emailIsRegistered(email: String) async throws -> Bool

    /// Clasifica un correo (RPC `check_email_account_kind`):
    /// `.repartidor` → OTP login · `.other` → bloquear · `.none` → signup.
    func emailAccountKind(email: String) async throws -> AccountKind

    /// Clasifica un teléfono (RPC `check_phone_account_kind`).
    func phoneAccountKind(phoneE164: String) async throws -> AccountKind

    /// Conjunto de roles que posee la cuenta (multi-rol). Vacío = no existe.
    /// A diferencia de `emailAccountKind` (un solo rol por prioridad), NO oculta
    /// roles: cada app pregunta "¿tengo MI rol?" mirando este conjunto.
    /// RPC `email_account_roles` / `phone_account_roles`.
    func emailAccountRoles(email: String) async throws -> Set<AccountKind>
    func phoneAccountRoles(phoneE164: String) async throws -> Set<AccountKind>

    /// Envía un código de un solo uso (magic code) al correo dado. Supabase manda
    /// un mail con 6 dígitos que el usuario ingresa en la OTPView.
    /// `shouldCreateUser` se mantiene en false: solo deja pasar correos ya registrados.
    func sendEmailOTP(email: String) async throws

    /// Verifica el código enviado a un correo y devuelve la sesión.
    func verifyEmailOTP(email: String, code: String) async throws -> AuthSession.Tokens

    /// Crea una sesión anónima cuando es soportado (BypassOTPAuthService).
    /// SupabaseAuthService throws — el flujo phone requiere OTP real.
    /// Útil cuando el usuario entra al signup-correo sin completar OTP previo.
    func signInAnonymously() async throws -> AuthSession.Tokens

    /// Inicia sign-in con Google via Supabase OAuth. La View pasa el
    /// `launchFlow` para que el SDK use ASWebAuthenticationSession.
    /// Returns tokens al completarse el callback.
    func signInWithGoogle(launchFlow: @escaping OAuthLaunchFlow) async throws -> AuthSession.Tokens

    /// Sign-in nativo con Google: la app obtiene el `idToken` con el SDK
    /// `GoogleSignIn` (selector nativo, sin mostrar el dominio de Supabase) y lo
    /// canjea con Supabase vía `signInWithIdToken`. Los `client IDs` de iOS deben
    /// estar autorizados en el provider Google de Supabase.
    func signInWithGoogle(idToken: String, accessToken: String?) async throws -> AuthSession.Tokens

    /// Inicia sesión con email + contraseña (login por contraseña que el usuario
    /// teclea, alternativa al OTP). Default lanza: solo la impl real (Supabase) lo
    /// soporta.
    func signInWithPassword(email: String, password: String) async throws -> AuthSession.Tokens

    /// Cambia la contraseña del usuario autenticado vía Supabase Auth
    /// (`auth.update(password:)`). Requiere sesión activa. `currentPassword`
    /// se recibe de la UI para futura re-verificación; hoy la sesión activa
    /// es la que autoriza el cambio.
    func updatePassword(currentPassword: String, newPassword: String) async throws

    /// Perfil básico del usuario autenticado (correo + nombre), para pre-llenar
    /// formularios (p. ej. el onboarding del negocio tras entrar con Google).
    /// nil si no hay sesión. Tiene default (nil) → es opt-in por implementación.
    func currentUserProfile() async throws -> AuthUserProfile?

    /// Pide a la Edge Function `tregga-emails` (kind `verify_cliente`) que mande
    /// un correo de verificación con enlace al usuario autenticado. No bloqueante:
    /// la cuenta ya existe; esto solo confirma la propiedad del correo.
    /// Default no-op → solo la impl real (Supabase) lo dispara.
    func requestEmailVerification() async throws

    /// Alta de cliente vía la API de Next.js (`/api/cliente/register`), NO directo contra Supabase:
    /// el registro debe pasar por el servidor para que capture la IP pública (`x-forwarded-for` →
    /// `profiles.registration_ip`). El endpoint crea la cuenta y devuelve la sesión; la impl real la
    /// establece y devuelve los tokens. Tiene default (Bypass/Mock) que cae al flujo local.
    func registerCliente(
        email: String,
        password: String,
        fullName: String,
        apellidoPaterno: String,
        apellidoMaterno: String?,
        phone: String?
    ) async throws -> AuthSession.Tokens
}

/// Datos mínimos del usuario autenticado para pre-llenar formularios.
public struct AuthUserProfile: Sendable, Equatable {
    public let email: String?
    public let name: String?
    public init(email: String?, name: String?) {
        self.email = email
        self.name = name
    }
}

public extension AuthService {
    /// Default: sin perfil. Las implementaciones con sesión real lo sobreescriben.
    func currentUserProfile() async throws -> AuthUserProfile? { nil }

    /// Default no-op: el Mock/Bypass no mandan correos reales.
    func requestEmailVerification() async throws {}

    /// Default: el sign-in nativo de Google solo aplica a la impl real (Supabase).
    func signInWithGoogle(idToken: String, accessToken: String?) async throws -> AuthSession.Tokens {
        throw AuthError.unknown("Google nativo no disponible en este modo.")
    }

    /// Default: el login con contraseña solo aplica a la impl real (Supabase).
    func signInWithPassword(email: String, password: String) async throws -> AuthSession.Tokens {
        throw AuthError.unknown("Login con contraseña no disponible en este modo.")
    }

    /// Default best-effort derivado del `kind` único (red de seguridad para
    /// conformers que no implementen el RPC de conjunto). Las impls reales
    /// (Supabase/Bypass) lo sobreescriben con `email_account_roles`.
    func emailAccountRoles(email: String) async throws -> Set<AccountKind> {
        let k = try await emailAccountKind(email: email)
        return k == .none ? [] : [k, .cliente]
    }
    func phoneAccountRoles(phoneE164: String) async throws -> Set<AccountKind> {
        let k = try await phoneAccountKind(phoneE164: phoneE164)
        return k == .none ? [] : [k, .cliente]
    }

    /// Default (Bypass/Mock, sin API): cae al alta local email+contraseña y devuelve la sesión
    /// resultante. La impl real (Supabase) lo sobreescribe con el POST a `/api/cliente/register`.
    func registerCliente(
        email: String,
        password: String,
        fullName: String,
        apellidoPaterno: String,
        apellidoMaterno: String?,
        phone: String?
    ) async throws -> AuthSession.Tokens {
        try await registerEmailPassword(email: email, password: password)
        guard let tokens = try await currentSession() else {
            throw AuthError.unknown("No se pudo iniciar la sesión tras el registro.")
        }
        return tokens
    }
}

public enum AuthError: Error, Equatable, Sendable {
    case invalidPhone
    case invalidCode
    case tooManyAttempts(retryAfterSeconds: Int)
    case networkFailure
    /// La red existe pero es **débil/inestable** (timeout, conexión perdida a
    /// mitad de la petición, host inalcanzable). Se distingue de `networkFailure`
    /// (sin red) para mostrar "conexión inestable" en vez de "sin conexión".
    case weakConnection
    case rateLimitedSMS(retryAfterSeconds: Int)
    /// La cuenta (teléfono o correo) no está registrada — la UI muestra un diálogo
    /// para crear cuenta o entrar con Google, en vez de auto-iniciar el registro.
    case accountNotRegistered
    /// La cuenta existe pero NO es repartidor (admin, cliente, negocio). Esta
    /// app es exclusiva de repartidores — la View muestra un dialog de rechazo.
    case accountNotRepartidor
    case unknown(String)
}

/// Clasificación de una cuenta para el login de Tregga Delivery.
/// Espejo del RPC `check_email_account_kind` / `check_phone_account_kind`.
public enum AccountKind: String, Sendable, Equatable {
    case cliente       // existe y es cliente         → app Food
    case negocio       // existe y es dueño de negocio → app Business
    case repartidor    // existe y es repartidor       → app Delivery
    case none          // no existe                    → signup
    // Cada app deja entrar SOLO a su rol (o cuenta nueva); el resto se bloquea
    // (cuentas separadas por rol: un correo = un rol).
}

@MainActor
public final class MockAuthService: AuthService {
    public var validCode: String
    public var lastPhone: String?
    public var lastEmail: String?
    public var attemptsByPhone: [String: Int] = [:]
    public var attemptsByEmail: [String: Int] = [:]

    public init(validCode: String = "1234") {
        self.validCode = validCode
    }

    public func sendOTP(phoneE164: String) async throws {
        guard phoneE164.hasPrefix("+52"), phoneE164.count == 13 else {
            throw AuthError.invalidPhone
        }
        lastPhone = phoneE164
        attemptsByPhone[phoneE164] = 0
    }

    public func verifyOTP(phoneE164: String, code: String) async throws -> AuthSession.Tokens {
        let attempts = (attemptsByPhone[phoneE164] ?? 0) + 1
        attemptsByPhone[phoneE164] = attempts
        if attempts > 5 {
            throw AuthError.tooManyAttempts(retryAfterSeconds: 300)
        }
        guard code == validCode else {
            throw AuthError.invalidCode
        }
        attemptsByPhone[phoneE164] = 0
        return AuthSession.Tokens(
            accessToken: "mock-access-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            userId: UUID()
        )
    }

    public func currentSession() async throws -> AuthSession.Tokens? {
        nil
    }

    public func currentUserIsAnonymous() async -> Bool { false }

    public func registerEmailPassword(email: String, password: String) async throws {}

    public func signOut() async throws {
        lastPhone = nil
        attemptsByPhone.removeAll()
    }

    public func signOutLocal() async throws {
        lastPhone = nil
        attemptsByPhone.removeAll()
    }

    public func restoreSession(refreshToken: String) async throws -> AuthSession.Tokens {
        // Mock: acepta cualquier refresh token recordado y devuelve una sesión.
        AuthSession.Tokens(
            accessToken: "mock-restored-\(UUID().uuidString)",
            refreshToken: refreshToken,
            userId: UUID()
        )
    }

    public func signInAnonymously() async throws -> AuthSession.Tokens {
        AuthSession.Tokens(
            accessToken: "mock-anon-\(UUID().uuidString)",
            refreshToken: "mock-anon-refresh-\(UUID().uuidString)",
            userId: UUID()
        )
    }

    public func signInWithGoogle(launchFlow: @escaping OAuthLaunchFlow) async throws -> AuthSession.Tokens {
        // Mock: no abre flujo OAuth real, solo genera tokens.
        AuthSession.Tokens(
            accessToken: "mock-google-\(UUID().uuidString)",
            refreshToken: "mock-google-refresh-\(UUID().uuidString)",
            userId: UUID()
        )
    }

    public func signInWithPassword(email: String, password: String) async throws -> AuthSession.Tokens {
        // Mock: acepta cualquier contraseña no vacía y devuelve tokens.
        guard !password.isEmpty else { throw AuthError.invalidCode }
        return AuthSession.Tokens(
            accessToken: "mock-pass-\(UUID().uuidString)",
            refreshToken: "mock-pass-refresh-\(UUID().uuidString)",
            userId: UUID()
        )
    }

    public func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard newPassword.count >= 8 else { throw AuthError.unknown("Contraseña muy corta") }
    }

    public func phoneIsRegistered(phoneE164: String) async throws -> Bool {
        // Mock: el teléfono de prueba "+525555555555" siempre existe.
        phoneE164 == "+525555555555"
    }

    public func emailIsRegistered(email: String) async throws -> Bool {
        (try await emailAccountKind(email: email)) == .repartidor
    }

    public func emailAccountKind(email: String) async throws -> AccountKind {
        // Mock por rol para probar la separación estricta de cada app.
        switch email.lowercased() {
        case "rep@tregga.app", "test@tregga.app": return .repartidor
        case "negocio@tregga.app":                return .negocio
        case "cliente@tregga.app":                return .cliente
        default:                                  return .none
        }
    }

    public func phoneAccountKind(phoneE164: String) async throws -> AccountKind {
        phoneE164 == "+525555555555" ? .repartidor : .none
    }

    public func emailAccountRoles(email: String) async throws -> Set<AccountKind> {
        switch email.lowercased() {
        case "rep@tregga.app", "test@tregga.app": return [.repartidor, .cliente]
        case "negocio@tregga.app":                return [.negocio, .cliente]
        case "cliente@tregga.app":                return [.cliente]
        default:                                  return []
        }
    }

    public func phoneAccountRoles(phoneE164: String) async throws -> Set<AccountKind> {
        phoneE164 == "+525555555555" ? [.repartidor, .cliente] : []
    }

    public func sendEmailOTP(email: String) async throws {
        guard email.contains("@") else { throw AuthError.unknown("Email inválido") }
        lastEmail = email
        attemptsByEmail[email] = 0
    }

    public func verifyEmailOTP(email: String, code: String) async throws -> AuthSession.Tokens {
        let attempts = (attemptsByEmail[email] ?? 0) + 1
        attemptsByEmail[email] = attempts
        if attempts > 5 { throw AuthError.tooManyAttempts(retryAfterSeconds: 300) }
        guard code == validCode else { throw AuthError.invalidCode }
        attemptsByEmail[email] = 0
        return AuthSession.Tokens(
            accessToken: "mock-email-\(UUID().uuidString)",
            refreshToken: "mock-email-refresh-\(UUID().uuidString)",
            userId: UUID()
        )
    }
}
