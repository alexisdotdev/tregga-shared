import SwiftUI

/// Mapa estático decorativo usado como fondo en pantallas de driver sin Google Maps.
/// Replica el SVG del handoff: calles, bloques de manzanas y capa de fondo.
public struct DriverMapPlaceholder: View {
    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                TreggaColors.mapBg.ignoresSafeArea()

                Canvas { ctx, size in
                    let sx = size.width  / 400
                    let sy = size.height / 700

                    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                        CGPoint(x: x * sx, y: y * sy)
                    }

                    let roadColor = TreggaColors.mapRoad
                    let blockColor = Color(UIColor { t in
                        t.userInterfaceStyle == .dark
                            ? UIColor(red: 0.086, green: 0.110, blue: 0.090, alpha: 1)
                            : UIColor(red: 0.863, green: 0.906, blue: 0.863, alpha: 1)
                    })

                    // Manzanas
                    let blocks: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                        (40, 250, 80, 80), (180, 80, 70, 60), (330, 120, 60, 70),
                        (40,  80, 60, 60), (160, 330, 90, 70), (300, 310, 80, 60),
                        (50, 400, 70, 60), (250, 470, 90, 40), (20, 520, 80, 60),
                        (180, 540, 90, 40), (300, 560, 80, 60),
                    ]
                    for (x, y, w, h) in blocks {
                        let r = CGRect(x: x * sx, y: y * sy, width: w * sx, height: h * sy)
                        ctx.fill(Path(roundedRect: r, cornerRadius: 2 * sx), with: .color(blockColor))
                    }

                    // Calles
                    struct Road { let path: (inout Path) -> Void; let width: CGFloat }
                    let roads: [Road] = [
                        Road(path: { p in
                            p.move(to: pt(-20, 180))
                            p.addQuadCurve(to: pt(260, 240), control: pt(140, 130))
                            p.addQuadCurve(to: pt(420, 260), control: pt(340, 250))
                        }, width: 42),
                        Road(path: { p in
                            p.move(to: pt(120, -20))
                            p.addQuadCurve(to: pt(60, 720), control: pt(140, 220))
                        }, width: 34),
                        Road(path: { p in
                            p.move(to: pt(-20, 480)); p.addLine(to: pt(420, 460))
                        }, width: 26),
                        Road(path: { p in
                            p.move(to: pt(310, -20)); p.addLine(to: pt(320, 340))
                        }, width: 22),
                        Road(path: { p in
                            p.move(to: pt(-20, 600))
                            p.addQuadCurve(to: pt(420, 620), control: pt(200, 580))
                        }, width: 22),
                    ]
                    for road in roads {
                        var path = Path()
                        road.path(&path)
                        ctx.stroke(path, with: .color(roadColor),
                                   style: StrokeStyle(lineWidth: road.width * sx, lineCap: .round, lineJoin: .round))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

#Preview("DriverMapPlaceholder") {
    DriverMapPlaceholder()
        .frame(height: 480)
        .clipShape(Rectangle())
}
