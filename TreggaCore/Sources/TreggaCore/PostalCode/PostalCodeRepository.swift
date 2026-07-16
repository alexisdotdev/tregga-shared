import Foundation

public struct PostalCodeInfo: Equatable, Sendable {
    public let codigoPostal: String
    public let colonias: [String]
    public let municipio: String
    public let estado: String
}

public protocol PostalCodeRepository: Sendable {
    func lookup(cp: String) async throws -> PostalCodeInfo?
}

public enum PostalCodeError: Error, Equatable, Sendable {
    case notFound
    case invalidFormat
    /// El servicio de CP no respondió (caída/red): NO significa que el CP no exista.
    case serviceUnavailable
}

@MainActor
public final class MockPostalCodeRepository: PostalCodeRepository {
    public init() {}

    public func lookup(cp: String) async throws -> PostalCodeInfo? {
        guard CPValidator.isValid(cp) else {
            throw PostalCodeError.invalidFormat
        }
        switch cp {
        case "61500":
            return PostalCodeInfo(
                codigoPostal: "61500",
                colonias: ["Centro", "La Joya", "San Antonio", "Ojo de Agua"],
                municipio: "Zinapécuaro",
                estado: "Michoacán"
            )
        case "61560":
            return PostalCodeInfo(
                codigoPostal: "61560",
                colonias: ["San Andrés", "El Salto"],
                municipio: "Zinapécuaro",
                estado: "Michoacán"
            )
        default:
            return nil
        }
    }
}
