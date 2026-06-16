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
        case chevR, chevL, chevD, chevU, chevUD
        case plus, minus, close, check
        case filter, more
        case checkCircle, closeCircle, arrowUp, arrowUpRight

        // Communication
        case bell, bellOff, heart, star, phone, message
        case mail, mailOpen, mailAdd

        // Location & time
        case pin, locationOff, clock, truck, bike

        // Payments
        case card, cash, wallet, dollar, bank, taxes, analytics

        // System
        case gift, tag, share, trash, edit, refresh, info
        case grid, moon, sun
        case arrow
        case warning, warningCircle, inbox, camera, settings, logout
        case bolt, flash, idea, play, help, faceId, idVerified, license
        case docClock, pdf, download, fileExport, copy, tap
        case qr, calendar, lock, shieldLock, wifiOff, location
        case car, wrench, box, speaker, speakerOff, image, chart, list
        case house, building, flag, turnLeft, turnRight, uturn, bug, ticket
        case eye, eyeOff

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
            case .chevUD:  return Hugeicons.unfoldMore
            case .plus:    return Hugeicons.add01
            case .minus:   return Hugeicons.remove01
            case .close:   return Hugeicons.cancel01
            case .check:   return Hugeicons.tick01
            case .filter:  return Hugeicons.filter
            case .more:    return Hugeicons.moreHorizontal
            case .checkCircle:  return Hugeicons.checkmarkCircle01
            case .closeCircle:  return Hugeicons.cancelCircle
            case .arrowUp:      return Hugeicons.arrowUp01
            case .arrowUpRight: return Hugeicons.arrowUpRight01

            // Communication
            case .bell:    return Hugeicons.notification01
            case .bellOff: return Hugeicons.notificationOff01
            case .heart:   return Hugeicons.heart
            case .star:    return Hugeicons.star
            case .phone:   return Hugeicons.call
            case .message: return Hugeicons.bubbleChat
            case .mail:    return Hugeicons.mail01
            case .mailOpen: return Hugeicons.mailOpen01
            case .mailAdd: return Hugeicons.mailAdd01

            // Location & time
            case .pin:     return Hugeicons.mapPin
            case .locationOff: return Hugeicons.navigationOff
            case .clock:   return Hugeicons.clock01
            case .truck:   return Hugeicons.truck
            case .bike:    return Hugeicons.bicycle

            // Payments
            case .card:    return Hugeicons.creditCard
            case .cash:    return Hugeicons.cash01
            case .wallet:  return Hugeicons.wallet01
            case .dollar:  return Hugeicons.dollarCircle
            case .bank:    return Hugeicons.bank
            case .taxes:   return Hugeicons.taxes
            case .analytics: return Hugeicons.analytics01

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
            case .warning:       return Hugeicons.alert02
            case .warningCircle: return Hugeicons.alertCircle
            case .inbox:   return Hugeicons.inbox
            case .camera:  return Hugeicons.camera01
            case .settings: return Hugeicons.settings01
            case .logout:  return Hugeicons.logout01
            case .bolt:    return Hugeicons.bolt
            case .flash:   return Hugeicons.flash
            case .idea:    return Hugeicons.idea01
            case .play:    return Hugeicons.playCircle02
            case .help:    return Hugeicons.helpCircle
            case .faceId:  return Hugeicons.faceId
            case .idVerified: return Hugeicons.idVerified
            case .license: return Hugeicons.license
            case .docClock: return Hugeicons.clipboardClock
            case .pdf:     return Hugeicons.pdf01
            case .download: return Hugeicons.download04
            case .fileExport: return Hugeicons.fileExport
            case .copy:    return Hugeicons.copy01
            case .tap:     return Hugeicons.tap01
            case .qr:      return Hugeicons.qrCode
            case .calendar: return Hugeicons.calendar03
            case .lock:    return Hugeicons.lock
            case .shieldLock: return Hugeicons.shieldKey
            case .eye:     return Hugeicons.eye
            case .eyeOff:  return Hugeicons.eyeOff
            case .wifiOff: return Hugeicons.wifiDisconnected01
            case .location: return Hugeicons.location01
            case .car:     return Hugeicons.car03
            case .wrench:  return Hugeicons.wrench01
            case .box:     return Hugeicons.deliveryBox01
            case .speaker: return Hugeicons.speaker
            case .speakerOff: return Hugeicons.volumeOff
            case .image:   return Hugeicons.image02
            case .chart:   return Hugeicons.chartBarLine
            case .list:    return Hugeicons.listView
            case .house:   return Hugeicons.house01
            case .building: return Hugeicons.building01
            case .flag:    return Hugeicons.racingFlag
            case .turnLeft: return Hugeicons.directionLeft01
            case .turnRight: return Hugeicons.directionRight01
            case .uturn:   return Hugeicons.arrowTurnBackward
            case .bug:     return Hugeicons.bug02
            case .ticket:  return Hugeicons.ticket01
            }
        }

        /// Resuelve un nombre de SF Symbol (usado por call sites data-driven)
        /// al caso Hugeicons más cercano. `nil` si no hay mapeo conocido.
        public init?(sfSymbol: String) {
            switch sfSymbol {
            case "house", "house.fill": self = .house
            case "magnifyingglass": self = .search
            case "bag", "bag.fill", "shippingbox.fill", "wallet.pass": self = .bag
            case "doc.text", "doc.fill", "list.bullet.rectangle": self = .receipt
            case "doc.text.clock": self = .docClock
            case "doc.on.doc": self = .copy
            case "arrow.down.doc", "arrow.down.circle": self = .download
            case "person", "person.fill", "person.circle", "person.crop.circle": self = .user
            case "person.crop.circle.badge.exclamationmark": self = .warningCircle
            case "chevron.right": self = .chevR
            case "chevron.left": self = .chevL
            case "chevron.down": self = .chevD
            case "chevron.up.chevron.down": self = .chevUD
            case "arrow.right": self = .arrow
            case "arrow.up": self = .arrowUp
            case "arrow.up.right": self = .arrowUpRight
            case "arrow.clockwise": self = .refresh
            case "plus": self = .plus
            case "minus": self = .minus
            case "xmark": self = .close
            case "xmark.circle.fill": self = .closeCircle
            case "checkmark": self = .check
            case "checkmark.circle.fill": self = .checkCircle
            case "info", "info.circle", "info.circle.fill", "questionmark.circle": self = .help
            case "exclamationmark.triangle", "exclamationmark.triangle.fill": self = .warning
            case "exclamationmark.circle", "exclamationmark.circle.fill": self = .warningCircle
            case "star.fill": self = .star
            case "heart", "heart.fill", "hand.raised": self = .heart
            case "bell", "bell.fill": self = .bell
            case "message", "message.fill": self = .message
            case "phone", "phone.fill": self = .phone
            case "envelope", "envelope.badge": self = .mail
            case "clock", "clock.fill", "calendar": self = .calendar
            case "mappin", "mappin.and.ellipse": self = .pin
            case "location", "location.fill": self = .location
            case "location.slash", "mappin.slash": self = .locationOff
            case "creditcard", "creditcard.fill": self = .card
            case "banknote", "banknote.fill": self = .cash
            case "dollarsign.circle.fill": self = .dollar
            case "building.columns", "building.columns.fill": self = .bank
            case "chart.bar": self = .chart
            case "camera", "camera.fill": self = .camera
            case "photo.fill": self = .image
            case "trash": self = .trash
            case "pencil": self = .edit
            case "gear", "gearshape": self = .settings
            case "square.and.arrow.up": self = .share
            case "rectangle.portrait.and.arrow.right": self = .logout
            case "tray": self = .inbox
            case "gift": self = .gift
            case "tag.fill": self = .tag
            case "moon": self = .moon
            case "bolt.fill": self = .bolt
            case "faceid": self = .faceId
            case "lock": self = .lock
            case "lock.shield": self = .shieldLock
            case "hand.tap.fill": self = .tap
            case "qrcode": self = .qr
            case "wifi.slash", "iphone.radiowaves.left.and.right": self = .wifiOff
            case "speaker.wave.2": self = .speaker
            case "car": self = .car
            case "bicycle": self = .bike
            case "wrench.and.screwdriver": self = .wrench
            case "ant": self = .bug
            case "play.circle.fill": self = .play
            // maneuver icons (DirectionCard)
            case "arrow.turn.up.left", "arrow.up.left": self = .turnLeft
            case "arrow.turn.up.right", "arrow.up.right": self = .turnRight
            case "arrow.uturn.up": self = .uturn
            case "flag.checkered": self = .flag
            default: return nil
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

    /// Init de compatibilidad para call sites data-driven que aún guardan el
    /// glifo como nombre de SF Symbol (string). Resuelve al caso Hugeicons más
    /// cercano; si no hay mapeo cae a `.info`.
    public init(
        sfSymbol: String,
        size: CGFloat = 22,
        color: Color = TreggaColors.text,
        weight: Font.Weight = .medium
    ) {
        self.init(Name(sfSymbol: sfSymbol) ?? .info, size: size, color: color, weight: weight)
    }

    public var body: some View {
        name.asset.image()
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }

    /// Raw Hugeicons `Image` para call sites que requieren un `Image` (no una
    /// `View`), como los slots `icon:` de `TreggaButton`, `DKV`, `Tag`, `Chip`.
    /// El componente que la recibe se encarga de hacerla `.resizable()` y
    /// aplicarle tamaño/color.
    @MainActor
    public static func image(_ name: Name) -> Image {
        name.asset.image()
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
