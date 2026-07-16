import Foundation

/// Lookup de códigos postales mexicanos vía SEPOMEX (servicio público).
/// Devuelve estado, municipio y lista de colonias para auto-llenar formularios.
/// Portado del repo legacy KMP (tregga-mobile/data/remote/PostalCodeService.kt).
public final class SepomexPostalCodeRepository: PostalCodeRepository {
    private static let baseURL = URL(string: "https://sepomex.nitrostudio.com.mx/api/20241009/cp")!
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func lookup(cp: String) async throws -> PostalCodeInfo? {
        let digitsOnly = cp.filter(\.isNumber)
        let clean = digitsOnly.count < 5
            ? String(repeating: "0", count: 5 - digitsOnly.count) + digitsOnly
            : digitsOnly
        guard clean.count == 5 else {
            throw PostalCodeError.invalidFormat
        }

        let url = Self.baseURL.appendingPathComponent("\(clean).json")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            // Fallo de transporte (sin red, timeout): el servicio no respondió,
            // NO es que el CP no exista.
            throw PostalCodeError.serviceUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw PostalCodeError.serviceUnavailable
        }
        // 5xx = caída del proveedor (SEPOMEX suele devolver 502 vía Cloudflare
        // cuando el origen está abajo). No confundir con "CP inexistente".
        guard http.statusCode < 500 else {
            throw PostalCodeError.serviceUnavailable
        }
        guard (200..<300).contains(http.statusCode) else {
            return nil
        }

        guard let decoded = try? JSONDecoder().decode(SepomexResponse.self, from: data) else {
            throw PostalCodeError.serviceUnavailable
        }
        guard let postcodes = decoded.data?.postcodes, !postcodes.isEmpty else {
            return nil
        }

        let first = postcodes[0]
        let colonias = Array(Set(postcodes.map(\.colonia))).sorted()

        return PostalCodeInfo(
            codigoPostal: clean,
            colonias: colonias,
            municipio: first.municipio,
            estado: first.estado
        )
    }

    // MARK: - SEPOMEX response shape

    private struct SepomexResponse: Decodable {
        let data: SepomexData?
        let error: String?
    }

    private struct SepomexData: Decodable {
        let totalRecords: Int
        let postcodes: [SepomexPostcode]

        enum CodingKeys: String, CodingKey {
            case totalRecords = "total_records"
            case postcodes
        }
    }

    private struct SepomexPostcode: Decodable {
        let colonia: String
        let municipio: String
        let estado: String

        enum CodingKeys: String, CodingKey {
            case colonia = "d_asenta"
            case municipio = "d_mnpio"
            case estado = "d_estado"
        }
    }
}
