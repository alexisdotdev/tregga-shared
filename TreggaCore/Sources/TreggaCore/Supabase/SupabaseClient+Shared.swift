import Foundation
import Supabase

/// Singleton del cliente Supabase compartido por todos los repositorios reales.
/// Lazy: se inicializa la primera vez que se accede.
public enum SupabaseClientShared {
    public static let client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: Config.SUPABASE_URL,
            supabaseKey: Config.SUPABASE_ANON_KEY,
            // Emite la sesión local guardada como sesión inicial (comportamiento
            // nuevo de supabase-swift): elimina el warning y unifica el arranque.
            options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
        )
    }()
}
