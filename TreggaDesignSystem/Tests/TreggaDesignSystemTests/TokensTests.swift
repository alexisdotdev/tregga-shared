import Testing
@testable import TreggaDesignSystem

@Suite("Token sanity checks")
struct TokensTests {

    @Test func radiusOrderingIsSane() {
        #expect(TreggaRadius.sm < TreggaRadius.md)
        #expect(TreggaRadius.md < TreggaRadius.lg)
        #expect(TreggaRadius.lg < TreggaRadius.xl)
        #expect(TreggaRadius.xl < TreggaRadius.xxl)
        #expect(TreggaRadius.pill == 100)
    }

    @Test func spacingOrderingIsSane() {
        #expect(TreggaSpacing.xxs < TreggaSpacing.xs)
        #expect(TreggaSpacing.xs  < TreggaSpacing.sm)
        #expect(TreggaSpacing.sm  < TreggaSpacing.md)
        #expect(TreggaSpacing.md  < TreggaSpacing.xl)
        #expect(TreggaSpacing.xl  < TreggaSpacing.huge)
    }

    @Test func textHierarchyIsDescending() {
        #expect(TreggaTextStyle.h1.size > TreggaTextStyle.h2.size)
        #expect(TreggaTextStyle.h2.size > TreggaTextStyle.h3.size)
        #expect(TreggaTextStyle.h3.size > TreggaTextStyle.h4.size)
        #expect(TreggaTextStyle.h4.size > TreggaTextStyle.body.size)
        #expect(TreggaTextStyle.body.size > TreggaTextStyle.sub.size)
        #expect(TreggaTextStyle.sub.size > TreggaTextStyle.caption.size)
        #expect(TreggaTextStyle.caption.size > TreggaTextStyle.micro.size)
    }

    @Test func displayStylesUseDisplayFamily() {
        #expect(TreggaTextStyle.h1.family == .display)
        #expect(TreggaTextStyle.h2.family == .display)
        #expect(TreggaTextStyle.displayNum.family == .display)
        #expect(TreggaTextStyle.displayNum.tabularNumbers == true)
    }

    @Test func bodyStylesUseBodyFamily() {
        #expect(TreggaTextStyle.h3.family == .body)
        #expect(TreggaTextStyle.h4.family == .body)
        #expect(TreggaTextStyle.body.family == .body)
        #expect(TreggaTextStyle.caption.family == .body)
    }
}
