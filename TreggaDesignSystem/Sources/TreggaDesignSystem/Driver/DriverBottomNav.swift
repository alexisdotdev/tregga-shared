import SwiftUI

public struct DriverBottomNav: View {
    public enum Tab: String, CaseIterable, Sendable, Identifiable {
        case home, earnings, trips, account

        public var id: String { rawValue }

        var label: String {
            switch self {
            case .home:     return "Inicio"
            case .earnings: return "Ganancias"
            case .trips:    return "Entregas"
            case .account:  return "Cuenta"
            }
        }

        var icon: String {
            switch self {
            case .home:     return "house.fill"
            case .earnings: return "creditcard.fill"
            case .trips:    return "list.bullet.clipboard.fill"
            case .account:  return "person.fill"
            }
        }
    }

    @Binding var active: Tab
    let onSelect: ((Tab) -> Void)?
    @Namespace private var highlightNamespace

    public init(active: Binding<Tab>, onSelect: ((Tab) -> Void)? = nil) {
        self._active = active
        self.onSelect = onSelect
    }

    public var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                modernGlassBody
            } else {
                legacyBody
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: - iOS 26 Liquid Glass (Apple Music style)

    @available(iOS 26.0, *)
    private var modernGlassBody: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 4) {
                ForEach(Tab.allCases) { tab in
                    modernTabButton(tab)
                }
            }
            .padding(6)
            .glassEffect(.regular, in: Capsule())
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func modernTabButton(_ tab: Tab) -> some View {
        let isActive = active == tab
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                active = tab
            }
            onSelect?(tab)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: isActive ? .bold : .semibold))
                Text(tab.label)
                    .font(.system(size: 10, weight: isActive ? .bold : .semibold))
                    .tracking(0.1)
            }
            .foregroundStyle(isActive ? TreggaColors.primary : TreggaColors.textSec)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isActive {
                    Capsule()
                        .fill(Color.clear)
                        .glassEffect(.clear.interactive(), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    .linearGradient(
                                        colors: [.white.opacity(0.45), .white.opacity(0.08)],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    lineWidth: 0.8
                                )
                        )
                        .glassEffectID("tab-highlight", in: highlightNamespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fallback iOS < 26

    private var legacyBody: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases) { tab in
                legacyTabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 64)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(tintFallback))
        )
        .overlay(
            Capsule()
                .strokeBorder(strokeColor, lineWidth: 0.5)
        )
        .clipShape(Capsule())
        .shadow(color: shadowColor, radius: 14, x: 0, y: 10)
        .shadow(color: shadowColor.opacity(0.4), radius: 3, x: 0, y: 1)
    }

    private func legacyTabButton(_ tab: Tab) -> some View {
        let isActive = active == tab
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                active = tab
            }
            onSelect?(tab)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: isActive ? .heavy : .semibold))
                Text(tab.label)
                    .font(.system(size: 10, weight: isActive ? .heavy : .semibold))
                    .tracking(0.1)
            }
            .foregroundStyle(isActive ? .white : TreggaColors.text)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(isActive ? TreggaColors.primary : Color.clear)
                    .shadow(color: isActive ? TreggaColors.primary.opacity(0.32) : .clear, radius: 8, x: 0, y: 4)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @Environment(\.colorScheme) private var scheme

    private var tintFallback: Color {
        scheme == .dark
            ? Color(red: 120/255, green: 120/255, blue: 128/255).opacity(0.28)
            : Color.white.opacity(0.55)
    }

    private var strokeColor: Color {
        scheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.06)
    }

    private var shadowColor: Color {
        scheme == .dark ? Color.black.opacity(0.35) : Color(red: 11/255, green: 15/255, blue: 13/255).opacity(0.10)
    }
}

#Preview("DriverBottomNav") {
    @Previewable @State var active: DriverBottomNav.Tab = .home
    ZStack(alignment: .bottom) {
        LinearGradient(
            colors: [TreggaColors.primarySoft, TreggaColors.bg],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
        DriverBottomNav(active: $active)
    }
}
