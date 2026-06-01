import SwiftUI

/// Title row with optional right-aligned action link.
public struct SectionHeader: View {
    let title: String
    let action: String?
    let onAction: (() -> Void)?

    public init(_ title: String, action: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    public var body: some View {
        HStack {
            Text(title)
                .treggaStyle(.h3)
                .foregroundStyle(TreggaColors.text)
            Spacer()
            if let action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .treggaStyle(.sub)
                        .fontWeight(.bold)
                        .foregroundStyle(TreggaColors.primary)
                }
                .buttonStyle(.plain)
                .disabled(onAction == nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

#Preview("SectionHeader") {
    VStack(spacing: 16) {
        SectionHeader("Últimos viajes", action: "Ver todos") { }
        SectionHeader("Desglose")
    }
    .padding(.vertical, 20)
    .background(TreggaColors.bg)
}
