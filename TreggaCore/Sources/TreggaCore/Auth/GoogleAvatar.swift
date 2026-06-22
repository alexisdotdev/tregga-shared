import Foundation
import Supabase
import Storage

/// Si el usuario entró con Google y su avatar es la URL de Google (o está vacío),
/// toma esa foto, la guarda en NUESTRO bucket `avatars/{uid}/avatar.jpg` y fija
/// `profiles.avatar_url` a la URL pública del bucket.
///
/// Por qué: el trigger `handle_new_user` deja la URL de `googleusercontent.com`
/// directamente en `avatar_url` — atada a Google (puede romperse al cambiar la
/// foto, depende de su CDN). Esto la convierte en un snapshot propio que el
/// usuario puede reemplazar después. Snapshot ÚNICO (no sincroniza con Google).
///
/// Best-effort: NO lanza. Un fallo (red, RLS, sin foto) no debe afectar el login.
/// Pensado para llamarse fire-and-forget tras `signInWithGoogle`.
public func sincronizarAvatarDeGoogle(client: SupabaseClient = SupabaseClientShared.client) async {
    guard let session = try? await client.auth.session else { return }
    let user = session.user

    // 1) URL de la foto de Google en el metadata del usuario.
    func metaString(_ keys: [String]) -> String? {
        for k in keys {
            if case let .string(v)? = user.userMetadata[k], !v.isEmpty { return v }
        }
        return nil
    }
    guard let urlStr = metaString(["avatar_url", "picture"]),
          let googleURL = URL(string: urlStr) else { return }
    let uid = user.id

    // 2) Solo migramos si el avatar actual está vacío o es una URL de Google.
    //    Si ya es del bucket (snapshot previo o foto subida por el usuario) NO se toca.
    struct Row: Decodable { let avatar_url: String? }
    let rows: [Row] = (try? await client.from("profiles")
        .select("avatar_url").eq("id", value: uid.uuidString).limit(1).execute().value) ?? []
    let actual = rows.first?.avatar_url ?? ""
    let esDeGoogle = actual.contains("googleusercontent.com")
    guard actual.isEmpty || esDeGoogle else { return }

    // 3) Descargar la foto de Google.
    guard let (data, _) = try? await URLSession.shared.data(from: googleURL), !data.isEmpty else { return }

    // 4) Subir a avatars/{uid}/avatar.jpg (bucket público). El prefijo va en
    //    minúsculas para empatar con la RLS (auth.uid()::text es lowercase).
    let path = "\(uid.uuidString.lowercased())/avatar.jpg"
    let bucket = client.storage.from("avatars")
    do {
        _ = try await bucket.upload(
            path, data: data,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )
    } catch {
        return
    }
    guard let publicURL = try? bucket.getPublicURL(path: path) else { return }

    // 5) Fijar profiles.avatar_url a la URL del bucket.
    struct Patch: Encodable { let avatar_url: String }
    _ = try? await client.from("profiles")
        .update(Patch(avatar_url: publicURL.absoluteString))
        .eq("id", value: uid.uuidString)
        .execute()
}
