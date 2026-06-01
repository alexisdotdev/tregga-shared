import SwiftUI

/// Driver-screen header with back arrow, title, optional subtitle and trailing slot.
public struct DriverHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let onBack: (() -> Void)?
    let trailing: Trailing

    public init(
        title: String,
        subtitle: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 10) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(TreggaColors.text)
                        .frame(width: 36, height: 36)
                        .background(TreggaColors.surface, in: Circle())
                        .overlay(Circle().stroke(TreggaColors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(-0.2)
                    .foregroundStyle(TreggaColors.text)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TreggaColors.textSec)
                        .lineLimit(1)
                }
            }

            Spacer()
            trailing
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(TreggaColors.bg)
        .overlay(TreggaDivider(), alignment: .bottom)
    }
}

#Preview("DriverHeader") {
    VStack(spacing: 0) {
        DriverHeader(title: "Carnitas Don Lupe", subtitle: "Pedido #4821", onBack: { }) {
            Image(systemName: "phone.fill")
                .font(.system(size: 16))
                .foregroundStyle(TreggaColors.text)
                .frame(width: 36, height: 36)
                .background(TreggaColors.surface, in: Circle())
        }
        Spacer()
    }
    .background(TreggaColors.bg)
}
