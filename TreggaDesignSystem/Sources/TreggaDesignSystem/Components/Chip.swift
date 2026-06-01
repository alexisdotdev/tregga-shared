import SwiftUI

/// Pill-shaped chip used for filters and quick actions.
public struct Chip: View {
    let label: String
    let isActive: Bool
    let icon: Image?
    let action: (() -> Void)?

    public init(
        _ label: String,
        isActive: Bool = false,
        icon: Image? = nil,
        action: (() -> Void)? = nil
    ) {
        self.label = label
        self.isActive = isActive
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 6) {
                if let icon {
                    icon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Text(label)
                    .font(.system(size: 13.5, weight: .semibold))
                    .tracking(-0.1)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .foregroundStyle(isActive ? TreggaColors.bg : TreggaColors.text)
            .background(
                Capsule().fill(isActive ? TreggaColors.text : TreggaColors.bg)
            )
            .overlay(
                Capsule().stroke(isActive ? TreggaColors.text : TreggaColors.border, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

#Preview("Chips") {
    HStack(spacing: 8) {
        Chip("Hoy", isActive: true) { }
        Chip("Esta semana") { }
        Chip("Este mes") { }
    }
    .padding(20)
    .background(TreggaColors.bg)
}
