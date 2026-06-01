import SwiftUI

/// Single-line key-value row used in driver summary screens.
public struct DKV: View {
    public enum Tone: Sendable { case `default`, primary }

    let label: String
    let value: String
    let icon: Image?
    let tone: Tone
    let isLast: Bool

    public init(
        label: String,
        value: String,
        icon: Image? = nil,
        tone: Tone = .default,
        isLast: Bool = false
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.tone = tone
        self.isLast = isLast
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if let icon {
                    icon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(tone == .primary ? TreggaColors.primary : TreggaColors.text)
                        .frame(width: 32, height: 32)
                        .background(TreggaColors.surface, in: RoundedRectangle(cornerRadius: 8))
                }
                Text(label)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(TreggaColors.textSec)
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(tone == .primary ? TreggaColors.primary : TreggaColors.text)
            }
            .padding(.vertical, 12)

            if !isLast { TreggaDivider() }
        }
    }
}

#Preview("DKV") {
    VStack(spacing: 0) {
        DKV(label: "Tiempo total", value: "18 min")
        DKV(label: "Distancia", value: "2.0 km")
        DKV(label: "Forma de pago", value: "Tarjeta")
        DKV(label: "Calificación", value: "5.0 ★", tone: .primary, isLast: true)
    }
    .padding(.horizontal, 16)
    .background(TreggaColors.bg)
}
