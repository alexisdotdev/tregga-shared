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
        // OTP por CORREO (no SMS). El servidor resuelve el correo de la cuenta del
        // teléfono y dispara el OTP por correo de Supabase. El correo nunca llega
        // al cliente (medida de seguridad: se descartó el SMS por completo).
        struct Body: Encodable { let phone: String }
        struct Resp: Decodable { let found: Bool? }
        let resp: Resp = try await postAuth("api/auth/phone-otp/request", body: Body(phone: phoneE164))
        if resp.found == false {
            throw AuthError.accountNotRegistered
        }
    }

    public func verifyOTP(phoneE164: String, code: String) async throws -> AuthSession.Tokens {
        // Verifica contra el servidor (que valida el OTP de correo) y establece la
        // sesión en el cliente con los tokens devueltos.
        struct Body: Encodable { let phone: String; let code: String }
        struct Resp: Decodable { let access_token: String; let refresh_token: String }
        let resp: Resp = try await postAuth(
            "api/auth/phone-otp/verify",
            body: Body(phone: phoneE164, code: code),
            invalidCodeOn401: true
        )
        do {
            let session = try await client.auth.setSession(
                accessToken: resp.access_token,
                refreshToken: resp.refresh_token
            )
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch {
            throw mapError(error)
        }
    }

    /// POST JSON a un endpoint de auth del API Next.js (tregga.app). Mapea 401 a
    /// `invalidCode` cuando aplica (verificación de OTP).
    private func postAuth<T: Decodable, B: Encodable>(
        _ path: String, body: B, invalidCodeOn401: Bool = false, conflictError: AuthError? = nil
    ) async throws -> T {
        var request = URLRequest(url: Config.API_BASE.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if invalidCodeOn401, status == 401 { throw AuthError.invalidCode }
            if let conflictError, status == 409 { throw conflictError }
            guard (200..<300).contains(status) else {
                throw AuthError.unknown("Error del servidor (\(status))")
            }
            return try JSONDecoder().decode(T.self, from: data)
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
        // Google guarda el nombre en full_name/name del user_metadata.
        return AuthUserProfile(email: user.email, name: metaString(["full_name", "name"]))
    }

    public func requestEmailVerification() async throws {
        struct Body: Encodable { let kind: String }
        // functions.invoke adjunta el Authorization: Bearer <jwt> de la sesión activa;
        // la Edge Function resuelve el correo del usuario y manda el enlace.
        try await client.functions.invoke(
            "tregga-emails",
            options: .init(body: Body(kind: "verify_cliente"))
        )
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func signOutLocal() async throws {
        // scope .local: limpia la sesión en este dispositivo SIN revocar el
        // refresh token en el servidor, para poder re-loguear con biometría.
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
            throw mapError(error)
        }
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

        // La RPC ya convirtió la cuenta server-side (is_anonymous=false); el JWT en
        // caché aún dice anónimo, así que refrescamos para corregirlo. PERO si el
        // refresh falla por red NO es fatal: la cuenta YA existe — lanzar haría que
        // el caller "limpie" un alta exitosa. Reintentamos y, si no, seguimos
        // (el token se corrige en el siguiente refresh: auto o al relanzar).
        for intento in 0..<3 {
            do {
                _ = try await client.auth.refreshSession()
                return
            } catch {
                if intento < 2 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
            }
        }
    }

    public func signInAnonymously() async throws -> AuthSession.Tokens {
        // Producción phone auth: no permitimos anonymous. El user debe completar OTP.
        throw AuthError.unknown("Sign-in anónimo no permitido en flujo Supabase real. Usa Phone OTP.")
    }

    public func registerCliente(
        email: String,
        password: String,
        fullName: String,
        apellidoPaterno: String,
        apellidoMaterno: String?,
        phone: String?
    ) async throws -> AuthSession.Tokens {
        // Alta vía la API de Next.js (captura la IP server-side en profiles.registration_ip).
        // El endpoint crea cuenta+cliente+perfil y devuelve la sesión; la establecemos aquí.
        struct Body: Encodable {
            let email: String
            let password: String
            let full_name: String
            let apellido_paterno: String
            let apellido_materno: String?
            let phone: String?
        }
        struct Resp: Decodable {
            let user_id: String
            let access_token: String?
            let refresh_token: String?
        }
        let resp: Resp = try await postAuth(
            "api/cliente/register",
            body: Body(
                email: email,
                password: password,
                full_name: fullName,
                apellido_paterno: apellidoPaterno,
                apellido_materno: apellidoMaterno,
                phone: phone
            ),
            conflictError: .unknown("Ese correo ya está registrado. Inicia sesión.")
        )
        guard let access = resp.access_token, let refresh = resp.refresh_token else {
            throw AuthError.unknown("El servidor no devolvió la sesión del registro.")
        }
        do {
            let session = try await client.auth.setSession(accessToken: access, refreshToken: refresh)
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch {
            throw mapError(error)
        }
    }

    public func phoneIsRegistered(phoneE164: String) async throws -> Bool {
        do {
            struct Params: Encodable { let p_phone: String }
            let exists: Bool = try await client.rpc(
                "check_phone_registered",
                params: Params(p_phone: phoneE164)
            ).execute().value
            return exists
        } catch {
            throw mapError(error)
        }
    }

    public func emailIsRegistered(email: String) async throws -> Bool {
        (try await emailAccountKind(email: email)) == .repartidor
    }

    public func emailAccountKind(email: String) async throws -> AccountKind {
        do {
            struct Params: Encodable { let p_email: String }
            let raw: String = try await client.rpc(
                "check_email_account_kind",
                params: Params(p_email: email)
            ).execute().value
            return AccountKind(rawValue: raw) ?? .none
        } catch {
            throw mapError(error)
        }
    }

    public func phoneAccountKind(phoneE164: String) async throws -> AccountKind {
        do {
            struct Params: Encodable { let p_phone: String }
            let raw: String = try await client.rpc(
                "check_phone_account_kind",
                params: Params(p_phone: phoneE164)
            ).execute().value
            return AccountKind(rawValue: raw) ?? .none
        } catch {
            throw mapError(error)
        }
    }

    public func emailAccountRoles(email: String) async throws -> Set<AccountKind> {
        do {
            struct Params: Encodable { let p_email: String }
            let raw: [String] = try await client.rpc(
                "email_account_roles",
                params: Params(p_email: email)
            ).execute().value
            return Set(raw.compactMap { AccountKind(rawValue: $0) })
        } catch {
            throw mapError(error)
        }
    }

    public func phoneAccountRoles(phoneE164: String) async throws -> Set<AccountKind> {
        do {
            struct Params: Encodable { let p_phone: String }
            let raw: [String] = try await client.rpc(
                "phone_account_roles",
                params: Params(p_phone: phoneE164)
            ).execute().value
            return Set(raw.compactMap { AccountKind(rawValue: $0) })
        } catch {
            throw mapError(error)
        }
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

        // El scheme del callback se deriva del bundle id de la app host: food y
        // delivery comparten este paquete, así que cada app debe recibir el
        // callback en SU propio scheme (registrado vía ASWebAuthenticationSession)
        // para volver a la app en lugar de abrir la otra app/web.
        let scheme = Bundle.main.bundleIdentifier ?? "app.tregga.food"
        let redirectURL = URL(string: "\(scheme)://login-callback")!
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
        // Migra la foto de Google a nuestro bucket en segundo plano (no bloquea
        // el login; el avatar se actualiza en cuanto termina).
        Task { await sincronizarAvatarDeGoogle(client: client) }
        return AuthSession.Tokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id
        )
    }

    public func signInWithGoogle(idToken: String, accessToken: String?) async throws -> AuthSession.Tokens {
        // Limpia cualquier sesión cacheada antes del nuevo login.
        try? await client.auth.signOut()
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            // Migra la foto de Google a nuestro bucket en segundo plano.
            Task { await sincronizarAvatarDeGoogle(client: client) }
            return AuthSession.Tokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
        } catch {
            throw mapError(error)
        }
    }

    public func updatePassword(currentPassword: String, newPassword: String) async throws {
        do {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> AuthError {
        // Clasificamos los fallos de red por **código** de URLError (no por
        // substring del mensaje, que confundía "conexión perdida" con "sin
        // internet"): sin red real → networkFailure; red débil/inestable
        // (timeout, conexión caída a mitad, host inalcanzable) → weakConnection.
        if let code = urlErrorCode(error) {
            switch code {
            case .notConnectedToInternet, .dataNotAllowed:
                return .networkFailure
            case .timedOut, .networkConnectionLost, .cannotConnectToHost,
                 .cannotFindHost, .dnsLookupFailed:
                return .weakConnection
            default:
                break
            }
        }
        let nsErr = error as NSError
        let msg = nsErr.localizedDescription.lowercased()
        if msg.contains("rate") {
            return .rateLimitedSMS(retryAfterSeconds: 60)
        }
        if msg.contains("invalid") && (msg.contains("token") || msg.contains("code")) {
            return .invalidCode
        }
        return .unknown(nsErr.localizedDescription)
    }

    /// Extrae el `URLError.Code` aun cuando supabase-swift envuelve el error de
    /// red en un `NSError` del dominio `NSURLErrorDomain`.
    private func urlErrorCode(_ error: Error) -> URLError.Code? {
        if let urlError = error as? URLError { return urlError.code }
        let nsErr = error as NSError
        guard nsErr.domain == NSURLErrorDomain else { return nil }
        return URLError.Code(rawValue: nsErr.code)
    }
}
