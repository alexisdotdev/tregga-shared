import SwiftUI

/// 1pt-tall horizontal divider that respects the theme `divider` token.
/// Named to avoid clashing with SwiftUI's built-in `Divider`.
public struct TreggaDivider: View {
    let inset: CGFloat

    public init(inset: CGFloat = 0) {
        self.inset = inset
    }

    public var body: some View {
        Rectangle()
            .fill(TreggaColors.divider)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}
