import Testing
import Foundation
@testable import TreggaCore

@Test func coreSmoke() {
    #expect(MoneyFormatter.format(centavos: 12345) == "$123.45")
}

// MARK: - AuthSession: ventana deslizante de inactividad (30 días)

/// Storage in-memory para tests (el protocolo lo anticipa).
private actor MockAuthStorage: AuthSecureStorage {
    private var store: [String: String] = [:]
    func set(_ value: String, forKey key: String) throws { store[key] = value }
    func get(key: String) throws -> String? { store[key] }
    func delete(key: String) throws { store.removeValue(forKey: key) }
}

private let day: TimeInterval = 24 * 60 * 60

private func seedTokens(_ storage: MockAuthStorage) async {
    try? await storage.set("access", forKey: AuthStorageKey.accessToken)
    try? await storage.set("refresh", forKey: AuthStorageKey.refreshToken)
    try? await storage.set(UUID().uuidString, forKey: AuthStorageKey.userId)
}

@Test @MainActor func sessionRestoresWhenRecent() async {
    let storage = MockAuthStorage()
    let session = AuthSession(storage: storage)
    await session.persist(.init(accessToken: "access", refreshToken: "refresh", userId: UUID()))

    let relaunch = AuthSession(storage: storage)
    await relaunch.restore()
    #expect(relaunch.isAuthenticated)
}

@Test @MainActor func sessionExpiresAfter30DaysInactive() async {
    let storage = MockAuthStorage()
    await seedTokens(storage)
    try? await storage.set(String(Date().timeIntervalSince1970 - 31 * day), forKey: AuthStorageKey.lastActiveAt)

    let session = AuthSession(storage: storage)
    await session.restore()
    #expect(!session.isAuthenticated)
    // La sesión se cerró por completo.
    let access = (try? await storage.get(key: AuthStorageKey.accessToken)) ?? nil
    #expect(access == nil)
}

@Test @MainActor func sessionSurvivesWithin30Days() async {
    let storage = MockAuthStorage()
    await seedTokens(storage)
    try? await storage.set(String(Date().timeIntervalSince1970 - 29 * day), forKey: AuthStorageKey.lastActiveAt)

    let session = AuthSession(storage: storage)
    await session.restore()
    #expect(session.isAuthenticated)
}

/// Sesiones previas al cambio (sin marca de actividad) no deben expirar de golpe:
/// se restauran y se les fija la ventana en ese momento.
@Test @MainActor func legacySessionWithoutTimestampSurvivesAndGetsStamped() async {
    let storage = MockAuthStorage()
    await seedTokens(storage)

    let session = AuthSession(storage: storage)
    await session.restore()
    #expect(session.isAuthenticated)
    let stamped = (try? await storage.get(key: AuthStorageKey.lastActiveAt)) ?? nil
    #expect(stamped != nil)
}
