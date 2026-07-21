import Foundation
import Supabase

/// Persiste el nombre que entrega Sign in with Apple.
///
/// Apple solo manda nombre y correo en la **primera** autorización de la app. Si no
/// se guarda en ese momento, no vuelve nunca: los siguientes inicios de sesión
/// traen el `idToken` sin `fullName` y el perfil se queda sin nombre para siempre.
///
/// Solo escribe si el perfil no tiene nombre todavía, para no pisar uno que el
/// usuario haya editado a mano. Es best-effort: si falla, el usuario puede ponerlo
/// desde su perfil.
public func guardarNombreDeAppleSiFalta(
    client: SupabaseClient = SupabaseClientShared.client,
    nombre: String
) async {
    let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !limpio.isEmpty else { return }
    guard let session = try? await client.auth.session else { return }
    let uid = session.user.id

    struct Row: Decodable { let name: String? }
    let rows: [Row] = (try? await client.from("profiles")
        .select("name").eq("id", value: uid.uuidString).limit(1).execute().value) ?? []

    // Si ya hay nombre, no se toca: el del usuario manda sobre el de Apple.
    if let actual = rows.first?.name, !actual.trimmingCharacters(in: .whitespaces).isEmpty {
        return
    }

    struct Patch: Encodable { let name: String }
    _ = try? await client.from("profiles")
        .update(Patch(name: limpio))
        .eq("id", value: uid.uuidString)
        .execute()
}
