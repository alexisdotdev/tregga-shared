import SwiftUI

/// Large stat block — e.g. "$487 · 8 viajes".
public struct DStat: View {
    public enum Tone: Sendable { case `default`, primary, accent, muted }
    public enum Alignment: Sendable { case leading, center }

    let label: String
    let value: String
    let sub: String?
    let tone: Tone
    let alignment: Alignment
    let big: Bool

    public init(
        label: String,
        value: String,
        sub: String? = nil,
        tone: Tone = .default,
        alignment: Alignment = .leading,
        big: Bool = false
    ) {
        self.label = label
        self.value = value
        self.sub = sub
        self.tone = tone
        self.alignment = alignment
        self.big = big
    }

    public var body: some View {
        VStack(alignment: alignment == .center ? .center : .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundStyle(TreggaColors.textSec)

            Text(value)
                .font(.system(size: big ? 40 : 28, weight: .heavy))
                .monospacedDigit()
                .tracking(-0.8)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 6)

            if let sub {
                Text(sub)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TreggaColors.textSec)
                    .padding(.top, 4)
            }
        }
    }

    private var valueColor: Color {
        switch tone {
        case .default: return TreggaColors.text
        case .primary: return TreggaColors.primary
        case .accent:  return TreggaColors.accent
        case .muted:   return TreggaColors.textSec
        }
    }
}

#Preview("DStat") {
    HStack(alignment: .top, spacing: 16) {
        DStat(label: "Ganaste", value: "$487", sub: "8 viajes · 4.5 hrs", tone: .primary, big: true)
        DStat(label: "Aceptación", value: "100%", sub: "Excelente")
        DStat(label: "Efectivo", value: "$145", sub: "Por entregar", tone: .accent)
    }
    .padding(20)
    .background(TreggaColors.bg)
}
