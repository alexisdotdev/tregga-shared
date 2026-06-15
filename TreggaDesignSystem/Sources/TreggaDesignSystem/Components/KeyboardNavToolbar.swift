import SwiftUI
import UIKit

// En iOS 26 la barra del teclado dibuja los botones de SOLO icono como chips
// circulares (se ven flotando). Los botones de TEXTO salen como pill plano, que
// es lo que queremos. Por eso usamos palabras ("Anterior/Siguiente/Listo").

public extension View {
    /// Barra sobre el teclado: "Anterior"/"Siguiente" para moverse entre los
    /// campos del formulario y "Listo" para ocultarlo. Igual en las 3 apps.
    ///
    /// Uso:
    /// ```
    /// enum Campo { case correo, password }
    /// @FocusState private var foco: Campo?
    /// ...
    /// TextField(...).focused($foco, equals: .correo)
    /// TextField(...).focused($foco, equals: .password)
    /// ...
    /// .keyboardNavToolbar($foco, order: [.correo, .password])
    /// ```
    func keyboardNavToolbar<Field: Hashable>(
        _ focus: FocusState<Field?>.Binding,
        order: [Field]
    ) -> some View {
        let index = focus.wrappedValue.flatMap { order.firstIndex(of: $0) }
        return toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Anterior") {
                    if let i = index, order.indices.contains(i - 1) { focus.wrappedValue = order[i - 1] }
                }
                .font(.system(size: 16, weight: .semibold))
                .disabled((index ?? 0) <= 0)

                Button("Siguiente") {
                    if let i = index, order.indices.contains(i + 1) { focus.wrappedValue = order[i + 1] }
                }
                .font(.system(size: 16, weight: .semibold))
                .disabled(index == nil || index! >= order.count - 1)

                Spacer()

                Button("Listo") {
                    focus.wrappedValue = nil
                }
                .font(.system(size: 16, weight: .bold))
            }
        }
        .tint(TreggaColors.primary)
    }

    /// Versión simple para pantallas de un solo campo (sin navegación): solo el
    /// botón "Listo" para ocultar el teclado.
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                }
                .font(.system(size: 16, weight: .bold))
            }
        }
        .tint(TreggaColors.primary)
    }
}
