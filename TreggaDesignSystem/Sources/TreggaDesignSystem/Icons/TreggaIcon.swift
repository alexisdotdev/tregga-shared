import SwiftUI

/// Tregga icon wrapper with a stable short-name API.
///
/// Currently maps short names to SF Symbols. The HTML/React prototype uses
/// `@hugeicons/core-free-icons`; once we add HugeiconsKit as a Swift Package
/// dependency we'll swap the body of `image` to use Hugeicons and keep the
/// public API identical so call sites don't change.
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

        var sfSymbol: String {
            switch self {
            // Navigation
            case .home:    return "house.fill"
            case .search:  return "magnifyingglass"
            case .bag:     return "bag.fill"
            case .receipt: return "doc.text.fill"
            case .user:    return "person.crop.circle.fill"
            case .chevR:   return "chevron.right"
            case .chevL:   return "chevron.left"
            case .chevD:   return "chevron.down"
            case .chevU:   return "chevron.up"
            case .plus:    return "plus"
            case .minus:   return "minus"
            case .close:   return "xmark"
            case .check:   return "checkmark"
            case .filter:  return "line.3.horizontal.decrease"
            case .more:    return "ellipsis"

            // Communication
            case .bell:    return "bell.fill"
            case .heart:   return "heart.fill"
            case .star:    return "star.fill"
            case .phone:   return "phone.fill"
            case .message: return "bubble.left.fill"

            // Location & time
            case .pin:     return "mappin.and.ellipse"
            case .clock:   return "clock.fill"
            case .truck:   return "shippingbox.fill"
            case .bike:    return "bicycle"

            // Payments
            case .card:    return "creditcard.fill"
            case .cash:    return "banknote.fill"
            case .wallet:  return "wallet.pass.fill"

            // System
            case .gift:    return "gift.fill"
            case .tag:     return "tag.fill"
            case .share:   return "square.and.arrow.up"
            case .trash:   return "trash"
            case .edit:    return "pencil"
            case .refresh: return "arrow.clockwise"
            case .info:    return "info.circle.fill"
            case .grid:    return "square.grid.2x2.fill"
            case .moon:    return "moon.fill"
            case .sun:     return "sun.max.fill"
            case .arrow:   return "arrow.right"
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
        Image(systemName: name.sfSymbol)
            .font(.system(size: size, weight: weight))
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
