import CoreGraphics

/// Spacing scale (pt). Multiples of 2 and 4.
public enum TreggaSpacing {
    public static let xxs:  CGFloat = 2
    public static let xs:   CGFloat = 4
    public static let sm:   CGFloat = 8
    public static let md:   CGFloat = 12
    public static let lg:   CGFloat = 14
    public static let xl:   CGFloat = 16
    public static let xxl:  CGFloat = 24
    public static let huge: CGFloat = 32
}

/// Corner radius scale (pt). Aligned with the JS prototype.
public enum TreggaRadius {
    public static let sm:   CGFloat = 8
    public static let md:   CGFloat = 10
    public static let lg:   CGFloat = 14
    public static let xl:   CGFloat = 16
    public static let xxl:  CGFloat = 18
    public static let huge: CGFloat = 24
    public static let pill: CGFloat = 100
}
