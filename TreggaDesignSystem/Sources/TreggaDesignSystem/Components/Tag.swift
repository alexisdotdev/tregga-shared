import SwiftUI

/// Small uppercase badge used inside cards and rows.
public struct Tag: View {
    public enum Tone: Sendable {
        case `default`
        case primary
        case accent
        case soft
        case warm
        case cash
        case danger
    }

    let label: String
    let tone: Tone
    let icon: Image?

    public init(_ label: String, tone: Tone = .default, icon: Image? = nil) {
        self.label = label
        self.tone = tone
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon { icon }
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.3)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .foregroundStyle(foreground)
        .background(background, in: RoundedRectangle(cornerRadius: TreggaRadius.sm))
    }

    private var background: Color {
        switch tone {
        case .default: return TreggaColors.surface
        case .primary: return TreggaColors.primary
        case .accent:  return TreggaColors.accent
        case .soft:    return TreggaColors.primarySoft
        case .warm:    return TreggaColors.accentSoft
        case .cash:    return TreggaColors.cashBg
        case .danger:  return TreggaColors.dangerBg
        }
    }

    private var foreground: Color {
        switch tone {
        case .default: return TreggaColors.text
        case .primary: return TreggaColors.onPrimary
        case .accent:  return .white
        case .soft:    return TreggaColors.primaryDark
        case .warm:    return TreggaColors.accent
        case .cash:    return TreggaColors.cashFg
        case .danger:  return TreggaColors.danger
        }
    }
}

/// Alias for `Tag`, used in driver-screen code for context clarity.
public typealias DTag = Tag

#Preview("Tags") {
    HStack(spacing: 8) {
        Tag("PROMO", tone: .primary)
        Tag("CASH", tone: .cash)
        Tag("EXTERNO", tone: .warm)
        Tag("CANCELADO", tone: .danger)
    }
    .padding(20)
    .background(TreggaColors.bg)
}
