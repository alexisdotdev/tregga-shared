import SwiftUI
import UIKit

public extension View {
    /// Barra sobre el teclado con flechas ↑/↓ para moverse entre los campos del
    /// formulario y un check (✓) para ocultar el teclado. Reemplaza al botón
    /// "Listo" suelto: navegación entre campos + cierre, igual en las 3 apps.
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
                Button {
                    if let i = index, order.indices.contains(i - 1) { focus.wrappedValue = order[i - 1] }
                } label: {
                    Image(systemName: "chevron.up").font(.system(size: 16, weight: .semibold))
                }
                .disabled((index ?? 0) <= 0)

                Button {
                    if let i = index, order.indices.contains(i + 1) { focus.wrappedValue = order[i + 1] }
                } label: {
                    Image(systemName: "chevron.down").font(.system(size: 16, weight: .semibold))
                }
                .disabled(index == nil || index! >= order.count - 1)

                Spacer()

                Button {
                    focus.wrappedValue = nil
                } label: {
                    Image(systemName: "checkmark").font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .tint(TreggaColors.primary)
    }

    /// Versión simple para pantallas de un solo campo (sin navegación): solo el
    /// check (✓) para ocultar el teclado.
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                } label: {
                    Image(systemName: "checkmark").font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .tint(TreggaColors.primary)
    }
}
