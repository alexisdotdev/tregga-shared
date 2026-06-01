import SwiftUI

/// Tregga type scale. Use the `.treggaStyle(_:)` modifier on `Text`.
///
/// ```swift
/// Text("Hola").treggaStyle(.h1)
/// ```
///
/// Two font families:
/// - `.body` — Plus Jakarta Sans (UI, body, headers h3/h4)
/// - `.display` — Sora (large numbers, h1/h2)
///
/// Until the custom fonts are registered, both families fall back to SF Pro
/// via `Font.system`. The `TreggaFontResolver` is the single swap point.
public struct TreggaTextStyle: Sendable, Equatable {
    public let size: CGFloat
    public let weight: Font.Weight
    public let tracking: CGFloat
    public let lineSpacing: CGFloat
    public let family: TreggaFontFamily
    public let tabularNumbers: Bool

    public init(
        size: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat = 0,
        lineHeightMultiple: CGFloat = 1.2,
        family: TreggaFontFamily = .body,
        tabularNumbers: Bool = false
    ) {
        self.size = size
        self.weight = weight
        self.tracking = tracking
        // SwiftUI `lineSpacing` is the *extra* gap between lines on top of
        // the natural baseline-to-baseline distance, hence the (m - 1) * size.
        self.lineSpacing = max(0, (lineHeightMultiple - 1.0) * size)
        self.family = family
        self.tabularNumbers = tabularNumbers
    }
}

public enum TreggaFontFamily: Sendable {
    case body    // Plus Jakarta Sans
    case display // Sora
}

// MARK: - Named styles
//
// Mirror the JS prototype's `tType` exactly so we can port designs 1:1.

public extension TreggaTextStyle {
    /// 32 / heavy / -0.6 / 1.05 · display
    static let h1       = TreggaTextStyle(size: 32, weight: .heavy,    tracking: -0.6, lineHeightMultiple: 1.05, family: .display)
    /// 24 / heavy / -0.4 / 1.10 · display
    static let h2       = TreggaTextStyle(size: 24, weight: .heavy,    tracking: -0.4, lineHeightMultiple: 1.10, family: .display)
    /// 20 / bold / -0.3 / 1.15
    static let h3       = TreggaTextStyle(size: 20, weight: .bold,     tracking: -0.3, lineHeightMultiple: 1.15)
    /// 17 / bold / -0.2 / 1.20
    static let h4       = TreggaTextStyle(size: 17, weight: .bold,     tracking: -0.2, lineHeightMultiple: 1.20)
    /// 15 / medium / -0.1 / 1.35
    static let body     = TreggaTextStyle(size: 15, weight: .medium,   tracking: -0.1, lineHeightMultiple: 1.35)
    /// 16 / medium / -0.1 / 1.40
    static let bodyLg   = TreggaTextStyle(size: 16, weight: .medium,   tracking: -0.1, lineHeightMultiple: 1.40)
    /// 13 / medium / 0 / 1.35
    static let sub      = TreggaTextStyle(size: 13, weight: .medium,   lineHeightMultiple: 1.35)
    /// 12 / semibold / 0.2 / 1.20
    static let caption  = TreggaTextStyle(size: 12, weight: .semibold, tracking: 0.2, lineHeightMultiple: 1.20)
    /// 11 / bold / 0.4 / 1.20 — for uppercase eyebrows
    static let micro    = TreggaTextStyle(size: 11, weight: .bold,     tracking: 0.4, lineHeightMultiple: 1.20)
    /// 44 / heavy / -1.0 / 1.00 · display + tabular — money / counters
    static let displayNum = TreggaTextStyle(size: 44, weight: .heavy,  tracking: -1.0, lineHeightMultiple: 1.00, family: .display, tabularNumbers: true)
}

// MARK: - View modifier

public extension View {
    /// Apply a Tregga text style: font + tracking + line spacing.
    func treggaStyle(_ style: TreggaTextStyle) -> some View {
        modifier(TreggaTextModifier(style: style))
    }
}

private struct TreggaTextModifier: ViewModifier {
    let style: TreggaTextStyle

    func body(content: Content) -> some View {
        content
            .font(TreggaFontResolver.font(for: style))
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}

// MARK: - Font resolver
//
// Single swap point: once Plus Jakarta Sans + Sora are registered as
// resources, change the body of `font(for:)` to return `Font.custom(...)`
// for each family.

enum TreggaFontResolver {
    static func font(for style: TreggaTextStyle) -> Font {
        var f = Font.system(size: style.size, weight: style.weight, design: .default)
        if style.tabularNumbers {
            f = f.monospacedDigit()
        }
        return f
    }
}

// MARK: - Preview

#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("h1 — Tregga Delivery").treggaStyle(.h1)
            Text("h2 — Ganancias de hoy").treggaStyle(.h2)
            Text("h3 — Pedido entrante").treggaStyle(.h3)
            Text("h4 — Carnitas Don Lupe").treggaStyle(.h4)
            Text("body — Av. Madero 87, Centro").treggaStyle(.body)
            Text("bodyLg — Pedido listo para recoger").treggaStyle(.bodyLg)
            Text("sub — Hace 2 minutos").treggaStyle(.sub)
            Text("caption — ETA").treggaStyle(.caption).textCase(.uppercase)
            Text("micro — VERIFICADO").treggaStyle(.micro).textCase(.uppercase)
            Text("$3,633.00")
                .treggaStyle(.displayNum)
                .foregroundStyle(TreggaColors.primary)
        }
        .foregroundStyle(TreggaColors.text)
        .padding(20)
    }
    .background(TreggaColors.bg)
}
