import Foundation

/// Configuración pública de Supabase y Google Maps.
/// Las keys se cargan desde Info.plist (expandido desde secrets.xcconfig).
public enum Config {
    public static var SUPABASE_URL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              !raw.isEmpty, !raw.contains("$"),
              let url = URL(string: raw) else {
            fatalError("SupabaseURL missing in Info.plist — check secrets.xcconfig")
        }
        return url
    }

    public static var SUPABASE_ANON_KEY: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
              !key.isEmpty, !key.contains("$") else {
            fatalError("SupabaseAnonKey missing in Info.plist — check secrets.xcconfig")
        }
        return key
    }

    /// Base de la API Next.js (tregga.app). Endpoints REST (p.ej. pagos OXXO).
    public static let API_BASE = URL(string: "https://tregga.app")!

    public static var GOOGLE_MAPS_API_KEY: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
              !key.isEmpty, !key.contains("$") else {
            return "PLACEHOLDER_ADD_TO_secrets.xcconfig"
        }
        return key
    }
}
