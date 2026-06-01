import SwiftUI

/// Vertical container that fills the screen with the theme background.
///
/// Equivalent to the `<Screen>` component in the React prototype.
public struct Screen<Content: View>: View {
    let padTop: CGFloat
    let padBottom: CGFloat
    let bg: Color?
    let content: Content

    public init(
        padTop: CGFloat = 60,
        padBottom: CGFloat = 90,
        bg: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padTop = padTop
        self.padBottom = padBottom
        self.bg = bg
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, padTop)
        .padding(.bottom, padBottom)
        .background(bg ?? TreggaColors.bg)
    }
}
