import SwiftUI

/// Brand pattern: dynamic horizontal stripes echoing the Tregga logo.
/// Used as hero background for splash, profile cards, promo banners.
///
/// Stripe positions are deterministic (mirrors the React prototype seeds).
public struct MotionStripes: View {
    let color: Color
    let tint: Color?

    public init(color: Color = TreggaColors.primaryDeep, tint: Color? = nil) {
        self.color = color
        self.tint = tint
    }

    // Mirror of `seeds` from the JS prototype. Each: (xRatio, yRatio, heightRatio).
    private static let seeds: [(CGFloat, CGFloat, CGFloat)] = [
        (0.00, 0.55, 0.060), (0.10, 0.35, 0.050), (0.00, 0.22, 0.050),
        (0.20, 0.18, 0.045), (0.30, 0.42, 0.050), (0.40, 0.30, 0.045),
        (0.00, 0.70, 0.050), (0.10, 0.80, 0.050), (0.30, 0.86, 0.050),
        (0.50, 0.62, 0.040), (0.60, 0.13, 0.045), (0.70, 0.74, 0.050),
        (0.00, 0.92, 0.045), (0.50, 0.95, 0.050), (0.20, 0.50, 0.040),
    ]

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .topLeading) {
                if let tint { tint }
                ForEach(Array(Self.seeds.enumerated()), id: \.offset) { idx, seed in
                    let length = (0.25 + CGFloat((idx * 37) % 60) / 100.0) * w
                    let stripeH = seed.2 * h
                    Capsule()
                        .fill(color)
                        .frame(width: length, height: stripeH)
                        .offset(x: seed.0 * w, y: seed.1 * h)
                }
            }
            .frame(width: w, height: h)
        }
    }
}

#Preview("MotionStripes") {
    VStack(spacing: 12) {
        ZStack {
            LinearGradient(
                colors: [TreggaColors.primaryDeep, TreggaColors.primary],
                startPoint: .top, endPoint: .bottom
            )
            MotionStripes(color: TreggaColors.primaryDeep)
                .opacity(0.35)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 18))

        ZStack {
            TreggaColors.primary
            MotionStripes(color: TreggaColors.primaryDeep)
                .opacity(0.6)
        }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    .padding(20)
    .background(TreggaColors.bg)
}
