import SwiftUI

public struct GoogleGIcon: View {
    public let size: CGFloat

    public init(size: CGFloat = 20) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            GoogleGYellow().fill(Color(red: 1.0, green: 0.757, blue: 0.027))
            GoogleGRed().fill(Color(red: 1.0, green: 0.239, blue: 0.0))
            GoogleGGreen().fill(Color(red: 0.298, green: 0.686, blue: 0.314))
            GoogleGBlue().fill(Color(red: 0.098, green: 0.463, blue: 0.824))
        }
        .frame(width: size, height: size)
    }
}

private struct GoogleGYellow: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 48
        let p = CGPoint(x: rect.minX, y: rect.minY)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: p.x + x * s, y: p.y + y * s)
        }
        var path = Path()
        path.move(to: pt(43.611, 20.083))
        path.addLine(to: pt(42, 20.083))
        path.addLine(to: pt(42, 20))
        path.addLine(to: pt(24, 20))
        path.addLine(to: pt(24, 28))
        path.addLine(to: pt(35.303, 28))
        path.addCurve(to: pt(24, 36), control1: pt(33.654, 32.657), control2: pt(29.223, 36))
        path.addCurve(to: pt(12, 24), control1: pt(17.373, 36), control2: pt(12, 30.627))
        path.addCurve(to: pt(24, 12), control1: pt(12, 17.373), control2: pt(17.373, 12))
        path.addCurve(to: pt(31.961, 15.039), control1: pt(27.059, 12), control2: pt(29.842, 13.154))
        path.addLine(to: pt(37.618, 9.382))
        path.addCurve(to: pt(24, 4), control1: pt(34.046, 6.053), control2: pt(29.268, 4))
        path.addCurve(to: pt(4, 24), control1: pt(12.955, 4), control2: pt(4, 12.955))
        path.addCurve(to: pt(24, 44), control1: pt(4, 35.045), control2: pt(12.955, 44))
        path.addCurve(to: pt(44, 24), control1: pt(35.045, 44), control2: pt(44, 35.045))
        path.addCurve(to: pt(43.611, 20.083), control1: pt(44, 22.659), control2: pt(43.862, 21.35))
        path.closeSubpath()
        return path
    }
}

private struct GoogleGRed: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 48
        let p = CGPoint(x: rect.minX, y: rect.minY)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: p.x + x * s, y: p.y + y * s)
        }
        var path = Path()
        path.move(to: pt(6.306, 14.691))
        path.addLine(to: pt(12.877, 19.510))
        path.addCurve(to: pt(24, 12), control1: pt(14.655, 15.108), control2: pt(18.961, 12))
        path.addCurve(to: pt(31.961, 15.039), control1: pt(27.059, 12), control2: pt(29.842, 13.154))
        path.addLine(to: pt(37.618, 9.382))
        path.addCurve(to: pt(24, 4), control1: pt(34.046, 6.053), control2: pt(29.268, 4))
        path.addCurve(to: pt(6.306, 14.691), control1: pt(16.318, 4), control2: pt(9.656, 8.337))
        path.closeSubpath()
        return path
    }
}

private struct GoogleGGreen: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 48
        let p = CGPoint(x: rect.minX, y: rect.minY)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: p.x + x * s, y: p.y + y * s)
        }
        var path = Path()
        path.move(to: pt(24, 44))
        path.addCurve(to: pt(37.409, 38.808), control1: pt(29.166, 44), control2: pt(33.860, 42.023))
        path.addLine(to: pt(31.219, 33.570))
        path.addCurve(to: pt(24, 36), control1: pt(29.103, 35.135), control2: pt(26.668, 36))
        path.addCurve(to: pt(12.717, 28.054), control1: pt(18.798, 36), control2: pt(14.381, 32.683))
        path.addLine(to: pt(6.195, 33.079))
        path.addCurve(to: pt(24, 44), control1: pt(9.505, 39.556), control2: pt(16.227, 44))
        path.closeSubpath()
        return path
    }
}

private struct GoogleGBlue: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 48
        let p = CGPoint(x: rect.minX, y: rect.minY)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: p.x + x * s, y: p.y + y * s)
        }
        var path = Path()
        path.move(to: pt(43.611, 20.083))
        path.addLine(to: pt(42, 20.083))
        path.addLine(to: pt(42, 20))
        path.addLine(to: pt(24, 20))
        path.addLine(to: pt(24, 28))
        path.addLine(to: pt(35.303, 28))
        path.addCurve(to: pt(31.216, 33.571), control1: pt(34.518, 30.219), control2: pt(33.119, 32.205))
        path.addLine(to: pt(31.219, 33.569))
        path.addLine(to: pt(37.409, 38.807))
        path.addCurve(to: pt(44, 24), control1: pt(36.971, 39.205), control2: pt(44, 34))
        path.addCurve(to: pt(43.611, 20.083), control1: pt(44, 22.659), control2: pt(43.862, 21.35))
        path.closeSubpath()
        return path
    }
}

#Preview("Google G") {
    HStack(spacing: 16) {
        GoogleGIcon(size: 20)
        GoogleGIcon(size: 32)
        GoogleGIcon(size: 64)
    }
    .padding(40)
}
