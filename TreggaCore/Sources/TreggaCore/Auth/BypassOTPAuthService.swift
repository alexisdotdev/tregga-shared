import Foundation
import Supabase
import Auth

/// AuthService de desarrollo/validación temprana que SALTA el envío y verificación
/// real de OTP. Cualquier código que ingrese el usuario se acepta. Se usa cuando
/// Twilio/WhatsApp Business todavía no están configurados y queremos validar el
/// flujo end-to-end con datos reales en Supabase sin gastar en provider SMS.
///
/// Internamente:
/// - `sendOTP` es no-op (simula éxito).
/// - `verifyOTP` ignora el código y crea o reusa una sesión vía **Supabase
///   Anonymous Sign-In**. Esto genera un `auth.users` real con `user.id` válido,
///   necesario para que el RPC `submit_repartidor` funcione con `auth.uid()`.
/// - Tras el sign-in, intenta asociar el teléfono al usuario (`auth.update`)
///   para que quede registrado, aunque sin verificar.
///
/// **Para apagar el modo**: en `AppDependencies`, setear `BYPASS_OTP=0` y usar
/// `SupabaseAuthService` (requiere Twilio/Bird/Vonage configurado en el Dashboard).
public final class BypassOTPAuthService: AuthService {
    private let client: SupabaseClient

    public init(client: SupabaseClient = SupabaseClientShared.client) {
        self.client = client
    }

    /// Phone OTP real (requiere Twilio/Bird/Vonage configurado en Supabase).
    /// El "bypass" original creaba un anonymous user nuevo y NO permitía login
    /// a repartidores existentes — eso era incorrecto para el flujo de login.
    public func sendOTP(phoneE164: String) async throws {
        guard phoneE164.hasPrefix("+52"), phoneE164.count == 13 else {
            throw AuthError.invalidPhone
        }
        do {
            try await client.auth.signInWithOTP(phone: phoneE164, shouldCreateUser: false)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    public func verifyOTP(phoneE164: String, code: String) async throws -> AuthSession.Tokens {
        do {
            let response = try await client.auth.verifyOTP(
                phone: phoneE164,
                token: code,
                type: .sms
            )
            guard let session = response.session else { throw AuthError.invalidCode }
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch let e as AuthError {
            throw e
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    public func currentSession() async throws -> AuthSession.Tokens? {
        guard let session = try? await client.auth.session else { return nil }
        return AuthSession.Tokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id
        )
    }

    public func currentUserProfile() async throws -> AuthUserProfile? {
        guard let session = try? await client.auth.session else { return nil }
        let user = session.user
        let meta = user.userMetadata
        func metaString(_ keys: [String]) -> String? {
            for k in keys {
                if case let .string(v)? = meta[k] { return v }
            }
            return nil
        }
        return AuthUserProfile(email: user.email, name: metaString(["full_name", "name"]))
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func signOutLocal() async throws {
        try await client.auth.signOut(scope: .local)
    }

    public func restoreSession(refreshToken: String) async throws -> AuthSession.Tokens {
        do {
            let session = try await client.auth.refreshSession(refreshToken: refreshToken)
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    public func currentUserIsAnonymous() async -> Bool {
        guard let session = try? await client.auth.session else { return false }
        return session.user.isAnonymous == true
    }

    public func registerEmailPassword(email: String, password: String) async throws {
        // Convierte el anónimo del signup en cuenta email+contraseña real e
        // inmediatamente utilizable, vía RPC server-side (evita el correo de
        // confirmación que dejaba la cuenta anónima/sin identidad).
        struct Params: Encodable { let p_email: String; let p_password: String }
        _ = try await client
            .rpc("convertir_anonimo_a_email", params: Params(p_email: email, p_password: password))
            .execute()

        // El refresh corrige el JWT local (is_anonymous=false). Si falla por red NO
        // es fatal: la cuenta YA existe server-side; lanzar haría que el caller
        // limpie un alta exitosa. Reintentamos y, si no, seguimos.
        for intento in 0..<3 {
            do {
                _ = try await client.auth.refreshSession()
                return
            } catch {
                if intento < 2 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
            }
        }
    }

    public func phoneIsRegistered(phoneE164: String) async throws -> Bool {
        struct Params: Encodable { let p_phone: String }
        let exists: Bool = try await client.rpc(
            "check_phone_registered",
            params: Params(p_phone: phoneE164)
        ).execute().value
        return exists
    }

    public func emailIsRegistered(email: String) async throws -> Bool {
        (try await emailAccountKind(email: email)) == .repartidor
    }

    public func emailAccountKind(email: String) async throws -> AccountKind {
        struct Params: Encodable { let p_email: String }
        let raw: String = try await client.rpc(
            "check_email_account_kind",
            params: Params(p_email: email)
        ).execute().value
        return AccountKind(rawValue: raw) ?? .none
    }

    public func phoneAccountKind(phoneE164: String) async throws -> AccountKind {
        struct Params: Encodable { let p_phone: String }
        let raw: String = try await client.rpc(
            "check_phone_account_kind",
            params: Params(p_phone: phoneE164)
        ).execute().value
        return AccountKind(rawValue: raw) ?? .none
    }

    /// El email OTP de Supabase funciona out-of-the-box (no requiere Twilio
    /// como SMS), por eso aunque estemos en Bypass mode para Phone, sí usamos
    /// la API real para correo: manda código y lo verifica contra Supabase.
    public func sendEmailOTP(email: String) async throws {
        do {
            try await client.auth.signInWithOTP(email: email, shouldCreateUser: false)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    public func verifyEmailOTP(email: String, code: String) async throws -> AuthSession.Tokens {
        do {
            let response = try await client.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )
            guard let session = response.session else { throw AuthError.invalidCode }
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch let e as AuthError {
            throw e
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    public func updatePassword(currentPassword: String, newPassword: String) async throws {
        do {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    public func signInWithGoogle(launchFlow: @escaping OAuthLaunchFlow) async throws -> AuthSession.Tokens {
        try? await client.auth.signOut()

        // Scheme derivado del bundle id de la app host (food/delivery comparten
        // este paquete) para que el callback vuelva a ESTA app y no a la otra.
        let scheme = Bundle.main.bundleIdentifier ?? "app.tregga.food"
        let redirectURL = URL(string: "\(scheme)://login-callback")!
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: redirectURL,
            launchFlow: launchFlow
        )

        let session = try await client.auth.session
        // Migra la foto de Google a nuestro bucket en segundo plano (no bloquea login).
        Task { await sincronizarAvatarDeGoogle(client: client) }
        return AuthSession.Tokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id
        )
    }

    public func signInAnonymously() async throws -> AuthSession.Tokens {
        // Igual que verifyOTP: limpia cualquier sesión cacheada en Keychain
        // que pudiera apuntar a un auth.users borrado, antes de crear el
        // nuevo anon user. Sin esto el upsert de profile/repartidor falla
        // con FK violation 23503.
        try? await client.auth.signOut()

        let session = try await client.auth.signInAnonymously()
        return AuthSession.Tokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id
        )
    }
}
