import SwiftUI

/// Barra de búsqueda. Dos modos:
/// - Decorativa: `SearchBar(placeholder:)` muestra solo el texto (no editable).
/// - Interactiva: `SearchBar(text:placeholder:)` con un `TextField` real enfocable.
public struct SearchBar: View {
    let placeholder: String
    let filled: Bool
    private let text: Binding<String>?

    public init(placeholder: String = "Buscar…", filled: Bool = true) {
        self.placeholder = placeholder
        self.filled = filled
        self.text = nil
    }

    /// Variante interactiva con binding de texto editable.
    public init(text: Binding<String>, placeholder: String = "Buscar…", filled: Bool = true) {
        self.placeholder = placeholder
        self.filled = filled
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 10) {
            TreggaIcon(.search, size: 19, color: TreggaColors.textSec)
            if let text {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(TreggaColors.textSec))
                    .treggaStyle(.bodyLg)
                    .foregroundStyle(TreggaColors.text)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
            } else {
                Text(placeholder)
                    .treggaStyle(.bodyLg)
                    .foregroundStyle(TreggaColors.textSec)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(filled ? TreggaColors.surface : TreggaColors.bg)
        .overlay(
            RoundedRectangle(cornerRadius: TreggaRadius.lg)
                .stroke(filled ? .clear : TreggaColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: TreggaRadius.lg))
    }
}

#Preview("SearchBar") {
    VStack(spacing: 12) {
        SearchBar(placeholder: "Busca un tema (efectivo, cancelaciones…)")
        SearchBar(placeholder: "Outlined", filled: false)
    }
    .padding(20)
    .background(TreggaColors.bg)
}
