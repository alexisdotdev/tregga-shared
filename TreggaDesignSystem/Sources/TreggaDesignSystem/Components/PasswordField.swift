import SwiftUI

/// Campo de contraseña con toggle de visibilidad (ojo). Inline: NO trae caja
/// propia, el caller lo envuelve en su estilo de campo (p. ej. RegistroField).
/// Reutilizable por las 3 apps del ecosistema.
///
/// El manejo de foco es opcional: usa el init con `focus`/`equals` cuando el
/// formulario navega con `@FocusState`; usa el init corto cuando no lo necesita.
public struct PasswordField<F: Hashable>: View {
    private let placeholder: String
    @Binding private var text: String
    private let focus: FocusState<F?>.Binding?
    private let equals: F?
    private let submitLabel: SubmitLabel
    private let onSubmit: () -> Void
    @State private var revealed = false

    private init(
        placeholder: String,
        text: Binding<String>,
        focus: FocusState<F?>.Binding?,
        equals: F?,
        submitLabel: SubmitLabel,
        onSubmit: @escaping () -> Void
    ) {
        self.placeholder = placeholder
        self._text = text
        self.focus = focus
        self.equals = equals
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    /// Con manejo de foco (`@FocusState`).
    public init(
        _ placeholder: String,
        text: Binding<String>,
        focus: FocusState<F?>.Binding,
        equals: F,
        submitLabel: SubmitLabel = .done,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.init(placeholder: placeholder, text: text, focus: focus, equals: equals,
                  submitLabel: submitLabel, onSubmit: onSubmit)
    }

    public var body: some View {
        HStack(spacing: 8) {
            field
                // El campo ocupa el ancho disponible y todo su área enfoca al tap.
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            Button { revealed.toggle() } label: {
                TreggaIcon(revealed ? .eyeOff : .eye, size: 18, color: TreggaColors.textSec)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(revealed ? "Ocultar contraseña" : "Mostrar contraseña")
        }
    }

    @ViewBuilder
    private var field: some View {
        let base = Group {
            if revealed {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }
        }
        .textContentType(.password)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .submitLabel(submitLabel)
        .onSubmit(onSubmit)

        if let focus, let equals {
            base.focused(focus, equals: equals)
        } else {
            base
        }
    }
}

public extension PasswordField where F == Int {
    /// Sin manejo de foco (el formulario no usa `@FocusState`).
    init(
        _ placeholder: String,
        text: Binding<String>,
        submitLabel: SubmitLabel = .done,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.init(placeholder: placeholder, text: text, focus: nil, equals: nil,
                  submitLabel: submitLabel, onSubmit: onSubmit)
    }
}
