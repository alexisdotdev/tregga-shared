import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Abre la página de **Ajustes de la app** en iOS.
///
/// Es lo más específico que Apple permite: NO se puede llevar al usuario a un
/// toggle concreto (p. ej. directo a "Ubicación"), solo a la pantalla de la app
/// dentro de Ajustes, donde ve todos sus permisos. Úsalo en los avisos de
/// permiso denegado para llevarlo a activarlo en un toque.
@MainActor
public func abrirAjustesDelSistema() {
    #if canImport(UIKit)
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
    #endif
}
