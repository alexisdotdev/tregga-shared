import Testing
@testable import TreggaCore

@Test func coreSmoke() {
    #expect(MoneyFormatter.format(centavos: 12345) == "$123.45")
}
