import SwiftUI
import UIKit

// Barra sobre el teclado con navegación ↑/↓ entre campos y ✓ para ocultar.
//
// Implementación: **toolbar nativo de SwiftUI** (`.toolbar(placement:.keyboard)`).
// Se presenta de forma atómica junto con el teclado, sin `inputAccessoryView`
// ni `reloadInputViews()` — por eso es fluida y nunca dispara el bucle de
// re-presentación que tenía la versión anterior (UIKit). La API pública no cambia.

public extension View {
    /// Barra sobre el teclado con flechas ↑/↓ para moverse entre los campos del
    /// formulario y un check (✓) para ocultarlo.
    ///
    /// Uso:
    /// ```
    /// enum Campo { case correo, password }
    /// @FocusState private var foco: Campo?
    /// ...
    /// TextField(...).focused($foco, equals: .correo)
    /// .keyboardNavToolbar($foco, order: [.correo, .password])
    /// ```
    func keyboardNavToolbar<Field: Hashable>(
        _ focus: FocusState<Field?>.Binding,
        order: [Field]
    ) -> some View {
        modifier(KeyboardNavToolbarModifier(focus: focus, order: order))
    }

    /// Versión simple para pantallas de un solo campo: solo el check (✓).
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: dismissKeyboard) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                }
                .tint(TreggaColors.primary)
            }
        }
    }
}

private struct KeyboardNavToolbarModifier<Field: Hashable>: ViewModifier {
    let focus: FocusState<Field?>.Binding
    let order: [Field]

    private var idx: Int? { focus.wrappedValue.flatMap { order.firstIndex(of: $0) } }

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    if let i = idx, i > 0 { focus.wrappedValue = order[i - 1] }
                } label: {
                    Image(systemName: "chevron.up").font(.system(size: 17, weight: .semibold))
                }
                .disabled((idx ?? 0) <= 0)

                Button {
                    if let i = idx, i < order.count - 1 {
                        focus.wrappedValue = order[i + 1]
                    } else {
                        // Último campo: ↓ oculta el teclado (lo "siguiente" puede ser
                        // un control no enfocable, p.ej. la rueda de fecha de nacimiento).
                        focus.wrappedValue = nil
                    }
                } label: {
                    Image(systemName: "chevron.down").font(.system(size: 17, weight: .semibold))
                }
                .disabled(idx == nil)

                Spacer()

                Button { focus.wrappedValue = nil } label: {
                    Image(systemName: "checkmark").font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .tint(TreggaColors.primary)
    }
}

private func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
    )
}
