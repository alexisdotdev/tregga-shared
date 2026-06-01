import SwiftUI

/// Primary action button used across the app.
public struct TreggaButton: View {
    public enum Kind: Sendable {
        case primary, secondary, ghost, dark, accent
    }

    let label: String
    let kind: Kind
    let icon: Image?
    let iconRight: Image?
    let isFullWidth: Bool
    let height: CGFloat
    let action: () -> Void

    public init(
        _ label: String,
        kind: Kind = .primary,
        icon: Image? = nil,
        iconRight: Image? = nil,
        isFullWidth: Bool = true,
        height: CGFloat = 52,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.kind = kind
        self.icon = icon
        self.iconRight = iconRight
        self.isFullWidth = isFullWidth
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { icon }
                Text(label)
                    .font(.system(size: height >= 56 ? 17 : 16, weight: .bold))
                    .tracking(-0.2)
                if let iconRight { iconRight }
            }
            .padding(.horizontal, isFullWidth ? 0 : 18)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: height)
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: TreggaRadius.lg).fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TreggaRadius.lg)
                    .stroke(borderColor, lineWidth: kind == .ghost ? 1 : 0)
            )
            .shadow(color: shadowColor, radius: 14, y: 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var backgroundFill: Color {
        switch kind {
        case .primary:   return TreggaColors.primary
        case .secondary: return TreggaColors.surface2
        case .ghost:     return .clear
        case .dark:      return TreggaColors.text
        case .accent:    return TreggaColors.accent
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary, .accent: return .white
        case .secondary, .ghost: return TreggaColors.text
        case .dark:              return TreggaColors.bg
        }
    }

    private var borderColor: Color {
        kind == .ghost ? TreggaColors.border : .clear
    }

    private var shadowColor: Color {
        kind == .primary ? TreggaColors.primary.opacity(0.25) : .clear
    }
}

#Preview("Buttons") {
    VStack(spacing: 12) {
        TreggaButton("Aceptar pedido", iconRight: Image(systemName: "arrow.right")) { }
        TreggaButton("Secundario", kind: .secondary) { }
        TreggaButton("Ghost", kind: .ghost) { }
        TreggaButton("Dark", kind: .dark) { }
        TreggaButton("Cobrar efectivo", kind: .accent) { }
        TreggaButton("Auto width", isFullWidth: false) { }
        TreggaButton("Grande", height: 60) { }
    }
    .padding(20)
    .background(TreggaColors.bg)
}
