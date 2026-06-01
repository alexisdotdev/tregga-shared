import SwiftUI

/// Stylized monoline scooter — used as vehicle illustration and dashboard
/// active-state icon. Hugeicons' bike icon is more bicycle-like, so we draw
/// our own.
public struct MotoIcon: View {
    let size: CGFloat
    let color: Color
    let lineWidth: CGFloat

    public init(size: CGFloat = 32, color: Color = TreggaColors.text, lineWidth: CGFloat = 1.8) {
        self.size = size
        self.color = color
        self.lineWidth = lineWidth
    }

    public var body: some View {
        Canvas { ctx, canvasSize in
            // Original viewBox is 32 x 24 (1.33 : 1 aspect)
            let sx = canvasSize.width  / 32.0
            let sy = canvasSize.height / 24.0
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * sx, y: y * sy)
            }

            // Wheels
            let wheelR: CGFloat = 4
            for c in [(6.0 as CGFloat, 18.0 as CGFloat), (24.0, 18.0)] {
                let rect = CGRect(
                    x: c.0 * sx - wheelR * sx,
                    y: c.1 * sy - wheelR * sy,
                    width: wheelR * 2 * sx,
                    height: wheelR * 2 * sy
                )
                ctx.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: lineWidth)
            }

            // Body silhouette
            var body = Path()
            body.move(to: pt(6, 18))
            body.addLine(to: pt(10, 8))
            body.addLine(to: pt(14, 8))
            body.addLine(to: pt(19, 14))
            body.addLine(to: pt(22, 14))
            body.addLine(to: pt(23.5, 18))

            // Handlebar
            body.move(to: pt(14, 8))
            body.addLine(to: pt(18, 8))

            // Floorboard
            body.move(to: pt(11, 14))
            body.addLine(to: pt(22, 14))

            ctx.stroke(
                body,
                with: .color(color),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size * 0.75)
    }
}

#Preview("MotoIcon") {
    HStack(spacing: 24) {
        MotoIcon(size: 32)
        MotoIcon(size: 48, color: TreggaColors.primary)
        MotoIcon(size: 70, color: TreggaColors.primary, lineWidth: 2.4)
    }
    .padding(20)
    .background(TreggaColors.bg)
}
