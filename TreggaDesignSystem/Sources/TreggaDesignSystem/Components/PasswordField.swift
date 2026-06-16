import SwiftUI

/// Campo de contraseña con toggle de visibilidad (ojo). Inline: NO trae caja
/// propia, el caller lo envuelve en su estilo de campo (p. ej. RegistroField).
/// Reutilizable por las 3 apps del ecosistema.
public struct PasswordField<F: Hashable>: View {
    private let placeholder: String
    @Binding private var text: String
    private let focus: FocusState<F?>.Binding
    private let equals: F
    private let submitLabel: SubmitLabel
    private let onSubmit: () -> Void
    @State private var revealed = false

    public init(
        _ placeholder: String,
        text: Binding<String>,
        focus: FocusState<F?>.Binding,
        equals: F,
        submitLabel: SubmitLabel = .done,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.focus = focus
        self.equals = equals
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 8) {
            Group {
                if revealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .focused(focus, equals: equals)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)

            Button { revealed.toggle() } label: {
                TreggaIcon(revealed ? .eyeOff : .eye, size: 18, color: TreggaColors.textSec)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(revealed ? "Ocultar contraseña" : "Mostrar contraseña")
        }
    }
}
