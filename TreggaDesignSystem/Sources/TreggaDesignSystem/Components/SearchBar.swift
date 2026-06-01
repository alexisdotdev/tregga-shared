import SwiftUI

/// Visual placeholder search bar. Currently non-interactive; will be
/// wired to a `TextField` binding when search is implemented.
public struct SearchBar: View {
    let placeholder: String
    let filled: Bool

    public init(placeholder: String = "Buscar…", filled: Bool = true) {
        self.placeholder = placeholder
        self.filled = filled
    }

    public var body: some View {
        HStack(spacing: 10) {
            TreggaIcon(.search, size: 19, color: TreggaColors.textSec)
            Text(placeholder)
                .treggaStyle(.bodyLg)
                .foregroundStyle(TreggaColors.textSec)
            Spacer()
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
