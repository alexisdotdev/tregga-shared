import Foundation
import Supabase
import Auth

/// AuthService real apoyado en supabase-swift (Phone OTP).
public final class SupabaseAuthService: AuthService {
    private let client: SupabaseClient

    public init(client: SupabaseClient = SupabaseClientShared.client) {
        self.client = client
    }

    public func sendOTP(phoneE164: String) async throws {
        guard phoneE164.hasPrefix("+52"), phoneE164.count == 13 else {
            throw AuthError.invalidPhone
        }
        do {
            try await client.auth.signInWithOTP(phone: phoneE164)
        } catch {
            throw mapError(error)
        }
    }

    public func verifyOTP(phoneE164: String, code: String) async throws -> AuthSession.Tokens {
        do {
            let response = try await client.auth.verifyOTP(
                phone: phoneE164,
                token: code,
                type: .sms
            )
            guard let session = response.session else {
                throw AuthError.invalidCode
            }
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch let e as AuthError {
            throw e
        } catch {
            throw mapError(error)
        }
    }

    public func currentSession() async throws -> AuthSession.Tokens? {
        do {
            let session = try await client.auth.session
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch {
            return nil
        }
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func currentUserIsAnonymous() async -> Bool {
        guard let session = try? await client.auth.session else { return false }
        return session.user.isAnonymous == true
    }

    public func registerEmailPassword(email: String, password: String) async throws {
        // Convierte el usuario anónimo del signup en una cuenta email+contraseña
        // REAL e inmediatamente utilizable, vía RPC server-side (evita el correo
        // de confirmación que dejaba la cuenta anónima/sin identidad).
        struct Params: Encodable { let p_email: String; let p_password: String }
        _ = try await client
            .rpc("convertir_anonimo_a_email", params: Params(p_email: email, p_password: password))
            .execute()
    }

    public func signInAnonymously() async throws -> AuthSession.Tokens {
        // Producción phone auth: no permitimos anonymous. El user debe completar OTP.
        throw AuthError.unknown("Sign-in anónimo no permitido en flujo Supabase real. Usa Phone OTP.")
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

    public func sendEmailOTP(email: String) async throws {
        do {
            // shouldCreateUser=false: solo manda a usuarios ya existentes; el path
            // de signup nunca pasa por aquí (lo enruta el WelcomeViewModel).
            try await client.auth.signInWithOTP(email: email, shouldCreateUser: false)
        } catch {
            throw mapError(error)
        }
    }

    public func verifyEmailOTP(email: String, code: String) async throws -> AuthSession.Tokens {
        do {
            let response = try await client.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )
            guard let session = response.session else {
                throw AuthError.invalidCode
            }
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch let e as AuthError {
            throw e
        } catch {
            throw mapError(error)
        }
    }

    public func signInWithGoogle(launchFlow: @escaping OAuthLaunchFlow) async throws -> AuthSession.Tokens {
        // Limpia cualquier sesión cacheada antes del nuevo OAuth.
        try? await client.auth.signOut()

        let redirectURL = URL(string: "app.tregga.delivery://login-callback")!
        do {
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL,
                launchFlow: launchFlow
            )
        } catch {
            throw mapError(error)
        }

        let session = try await client.auth.session
        return AuthSession.Tokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id
        )
    }

    public func updatePassword(currentPassword: String, newPassword: String) async throws {
        do {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> AuthError {
        let nsErr = error as NSError
        let msg = nsErr.localizedDescription.lowercased()
        if msg.contains("rate") {
            return .rateLimitedSMS(retryAfterSeconds: 60)
        }
        if msg.contains("network") || msg.contains("connection") {
            return .networkFailure
        }
        if msg.contains("invalid") && (msg.contains("token") || msg.contains("code")) {
            return .invalidCode
        }
        return .unknown(nsErr.localizedDescription)
    }
}
