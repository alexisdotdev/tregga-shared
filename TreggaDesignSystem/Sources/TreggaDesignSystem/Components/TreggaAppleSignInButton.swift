import SwiftUI
import AuthenticationServices
import CryptoKit

/// Botón oficial de Sign in with Apple, con el manejo del nonce resuelto dentro.
///
/// Vive en el paquete compartido a propósito: las tres apps lo necesitan por la
/// guía 4.8 de App Store, y el nonce es la parte fácil de copiar mal. Duplicarlo
/// en tres sitios es la forma que han tenido casi todos los bugs de este proyecto.
///
/// **Sobre el nonce**: a Apple se le manda el SHA-256 y al backend el valor en
/// claro. El backend comprueba que uno sea el hash del otro, lo que impide que un
/// tercero que intercepte el `idToken` lo reutilice. Mandar el mismo valor a los
/// dos lados anula la protección.
public struct TreggaAppleSignInButton: View {
    /// Devuelve el `idToken`, el nonce EN CLARO y el nombre completo si Apple lo
    /// entregó (solo lo hace en la primera autorización).
    public var onCredential: (_ idToken: String, _ nonce: String, _ fullName: String?) -> Void
    public var onError: (Error) -> Void
    public var height: CGFloat

    @Environment(\.colorScheme) private var colorScheme
    @State private var nonceEnClaro: String = ""

    public init(
        height: CGFloat = 56,
        onCredential: @escaping (_ idToken: String, _ nonce: String, _ fullName: String?) -> Void,
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        self.height = height
        self.onCredential = onCredential
        self.onError = onError
    }

    public var body: some View {
        SignInWithAppleButton(.continue) { request in
            let nonce = Self.nonceAleatorio()
            nonceEnClaro = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)
        } onCompletion: { resultado in
            switch resultado {
            case .success(let auth):
                guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                      let tokenData = cred.identityToken,
                      let idToken = String(data: tokenData, encoding: .utf8)
                else {
                    onError(TreggaAppleSignInError.sinIdentityToken)
                    return
                }
                let nombre = [cred.fullName?.givenName, cred.fullName?.familyName]
                    .compactMap { $0?.isEmpty == false ? $0 : nil }
                    .joined(separator: " ")
                onCredential(idToken, nonceEnClaro, nombre.isEmpty ? nil : nombre)

            case .failure(let error):
                // Cancelar no es un fallo que merezca mensaje de error.
                if (error as? ASAuthorizationError)?.code == .canceled { return }
                onError(error)
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: TreggaRadius.lg))
    }

    // MARK: - Nonce

    private static func nonceAleatorio(longitud: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: longitud)
        let status = SecRandomCopyBytes(kSecRandomDefault, longitud, &bytes)
        guard status == errSecSuccess else {
            // Fuente de aleatoriedad del sistema no disponible: es preferible un
            // UUID a devolver algo predecible.
            return UUID().uuidString + UUID().uuidString
        }
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

public enum TreggaAppleSignInError: LocalizedError {
    case sinIdentityToken

    public var errorDescription: String? {
        switch self {
        case .sinIdentityToken:
            return "Apple no devolvió el token de identidad. Intenta de nuevo."
        }
    }
}
