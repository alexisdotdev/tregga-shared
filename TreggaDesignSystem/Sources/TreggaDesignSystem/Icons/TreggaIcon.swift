import SwiftUI
import Hugeicons

/// Tregga icon wrapper with a stable short-name API.
///
/// Backed by Hugeicons (stroke rounded, grid 24x24). Cada caso de `Name` mapea
/// al `HugeiconsAsset` más cercano vía `Hugeicons.<id>.image()`. La API pública
/// (init + casos) se mantiene idéntica a la versión basada en SF Symbols.
public struct TreggaIcon: View {
    public enum Name: String, Sendable, CaseIterable {
        // Navigation
        case home, search, bag, receipt, user
        case chevR, chevL, chevD, chevU
        case plus, minus, close, check
        case filter, more

        // Communication
        case bell, heart, star, phone, message

        // Location & time
        case pin, clock, truck, bike

        // Payments
        case card, cash, wallet

        // System
        case gift, tag, share, trash, edit, refresh, info
        case grid, moon, sun
        case arrow

        /// Hugeicons asset que respalda cada caso. Stroke rounded, grid 24x24.
        var asset: HugeiconsAsset {
            switch self {
            // Navigation
            case .home:    return Hugeicons.home01
            case .search:  return Hugeicons.search01
            case .bag:     return Hugeicons.shoppingBag01
            case .receipt: return Hugeicons.invoice01
            case .user:    return Hugeicons.userCircle
            case .chevR:   return Hugeicons.arrowRight01
            case .chevL:   return Hugeicons.arrowLeft01
            case .chevD:   return Hugeicons.arrowDown01
            case .chevU:   return Hugeicons.arrowUp01
            case .plus:    return Hugeicons.add01
            case .minus:   return Hugeicons.remove01
            case .close:   return Hugeicons.cancel01
            case .check:   return Hugeicons.tick01
            case .filter:  return Hugeicons.filter
            case .more:    return Hugeicons.moreHorizontal

            // Communication
            case .bell:    return Hugeicons.notification01
            case .heart:   return Hugeicons.heart
            case .star:    return Hugeicons.star
            case .phone:   return Hugeicons.call
            case .message: return Hugeicons.bubbleChat

            // Location & time
            case .pin:     return Hugeicons.mapPin
            case .clock:   return Hugeicons.clock01
            case .truck:   return Hugeicons.truck
            case .bike:    return Hugeicons.bicycle

            // Payments
            case .card:    return Hugeicons.creditCard
            case .cash:    return Hugeicons.cash01
            case .wallet:  return Hugeicons.wallet01

            // System
            case .gift:    return Hugeicons.gift
            case .tag:     return Hugeicons.tag01
            case .share:   return Hugeicons.share01
            case .trash:   return Hugeicons.delete01
            case .edit:    return Hugeicons.edit01
            case .refresh: return Hugeicons.refresh
            case .info:    return Hugeicons.informationCircle
            case .grid:    return Hugeicons.dashboardSquare01
            case .moon:    return Hugeicons.moon
            case .sun:     return Hugeicons.sun01
            case .arrow:   return Hugeicons.arrowRight01
            }
        }
    }

    let name: Name
    let size: CGFloat
    let color: Color
    let weight: Font.Weight

    public init(
        _ name: Name,
        size: CGFloat = 22,
        color: Color = TreggaColors.text,
        weight: Font.Weight = .medium
    ) {
        self.name = name
        self.size = size
        self.color = color
        self.weight = weight
    }

    public var body: some View {
        name.asset.image()
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }
}

#Preview("Icons") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
            ForEach(TreggaIcon.Name.allCases, id: \.self) { name in
                VStack(spacing: 6) {
                    TreggaIcon(name, size: 22)
                    Text(name.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(TreggaColors.textSec)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
    }
    .background(TreggaColors.bg)
}
