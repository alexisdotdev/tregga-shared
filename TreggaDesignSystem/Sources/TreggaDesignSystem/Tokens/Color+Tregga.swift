import SwiftUI
import UIKit

/// Tregga brand colors with full light + dark mode support.
///
/// Colors auto-switch based on the current `userInterfaceStyle`.
/// To pin a color to a specific scheme, attach
/// `.environment(\.colorScheme, .dark)` to the view.
public enum TreggaColors {

    // MARK: - Brand

    public static let primary      = dyn(light: 0x0DB55C, dark: 0x2DD37A)
    public static let primaryDark  = dyn(light: 0x079247, dark: 0x23B466)
    public static let primaryDeep  = dyn(light: 0x055E2D, dark: 0x0E5B33)
    public static let primarySoft  = dyn(light: 0xE4F7EC, dark: 0x0F2218)
    public static let onPrimary    = dyn(light: 0xFFFFFF, dark: 0x062013)

    // MARK: - Accent (promos, cobros externos)

    public static let accent       = dyn(light: 0xFF6B2C, dark: 0xFF8A4D)
    public static let accentSoft   = dyn(light: 0xFFEDDC, dark: 0x311A0E)

    // MARK: - Semantic

    public static let warning      = dyn(light: 0xF2B600, dark: 0xF5C13C)
    public static let star         = dyn(light: 0xF5AB0E, dark: 0xF5C13C)
    public static let danger       = dyn(light: 0xE5474B, dark: 0xFF6B6E)
    public static let dangerBg     = dyn(light: 0xFFE3E0, dark: 0x3A1717)

    // Driver cash collection
    public static let cashBg       = dyn(light: 0xDCF0E5, dark: 0x1C2A22)
    public static let cashFg       = dyn(light: 0x1F8A5B, dark: 0x7FD7A8)

    // MARK: - Surfaces

    public static let bg           = dyn(light: 0xFFFFFF, dark: 0x070B09)
    public static let surface      = dyn(light: 0xF6F7F5, dark: 0x10140F)
    public static let surface2     = dyn(light: 0xECEEEB, dark: 0x1A201B)
    public static let card         = dyn(light: 0xFFFFFF, dark: 0x141911)
    public static let border       = dyn(light: 0xE7EAE5, dark: 0x222A23)
    public static let divider      = dynAlpha(light: 0x0B0F0D, lightA: 0.06, dark: 0xFFFFFF, darkA: 0.07)

    // MARK: - Text

    public static let text         = dyn(light: 0x0B0F0D, dark: 0xF4F7F4)
    public static let textSec      = dyn(light: 0x5F6B66, dark: 0xA6AFA8)
    public static let textTer      = dyn(light: 0x98A19D, dark: 0x6B7670)
    public static let inverse      = dyn(light: 0xFFFFFF, dark: 0x070B09)

    // MARK: - Map

    public static let mapBg        = dyn(light: 0xE8EFE9, dark: 0x0E1612)
    public static let mapRoad      = dyn(light: 0xFFFFFF, dark: 0x1B231D)
    public static let mapLine      = dyn(light: 0x0DB55C, dark: 0x2DD37A)

    // MARK: - Helpers

    private static func dyn(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }

    private static func dynAlpha(light: UInt32, lightA: CGFloat, dark: UInt32, darkA: CGFloat) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkA)
                : UIColor(hex: light, alpha: lightA)
        })
    }
}

public extension UIColor {
    /// Initialize with a 24-bit RGB hex value, e.g. `0x0DB55C`.
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >>  8) / 255.0
        let b = CGFloat( hex & 0x0000FF       ) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - Previews

#Preview("Colors · light") {
    ColorTokensPreview().preferredColorScheme(.light)
}

#Preview("Colors · dark") {
    ColorTokensPreview().preferredColorScheme(.dark)
}

private struct ColorTokensPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                row("Brand", swatches: [
                    ("primary", TreggaColors.primary),
                    ("primaryDark", TreggaColors.primaryDark),
                    ("primaryDeep", TreggaColors.primaryDeep),
                    ("primarySoft", TreggaColors.primarySoft),
                ])
                row("Accent", swatches: [
                    ("accent", TreggaColors.accent),
                    ("accentSoft", TreggaColors.accentSoft),
                ])
                row("Driver", swatches: [
                    ("cashBg", TreggaColors.cashBg),
                    ("cashFg", TreggaColors.cashFg),
                    ("dangerBg", TreggaColors.dangerBg),
                    ("danger", TreggaColors.danger),
                ])
                row("Surfaces", swatches: [
                    ("bg", TreggaColors.bg),
                    ("surface", TreggaColors.surface),
                    ("surface2", TreggaColors.surface2),
                    ("card", TreggaColors.card),
                    ("border", TreggaColors.border),
                ])
                row("Text", swatches: [
                    ("text", TreggaColors.text),
                    ("textSec", TreggaColors.textSec),
                    ("textTer", TreggaColors.textTer),
                ])
                row("Map", swatches: [
                    ("mapBg", TreggaColors.mapBg),
                    ("mapRoad", TreggaColors.mapRoad),
                    ("mapLine", TreggaColors.mapLine),
                ])
            }
            .padding(20)
        }
        .background(TreggaColors.bg)
    }

    @ViewBuilder
    private func row(_ title: String, swatches: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(TreggaColors.textSec)
            HStack(spacing: 8) {
                ForEach(Array(swatches.enumerated()), id: \.offset) { _, s in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(s.1)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(TreggaColors.border, lineWidth: 1))
                            .frame(width: 64, height: 48)
                        Text(s.0)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(TreggaColors.textSec)
                    }
                }
            }
        }
    }
}
