import Foundation

/// Lookup de códigos postales contra **nuestro** Supabase (RPC `lookup_cp`), que
/// sirve el padrón SEPOMEX auto-hospedado. Reemplaza al proveedor de terceros
/// (`SepomexPostalCodeRepository` → nitrostudio) que dejó de responder (502).
///
/// Misma semántica de errores que `SepomexPostalCodeRepository`, así que la UI
/// que ya distingue `invalidFormat` / no-encontrado / `serviceUnavailable` sigue
/// funcionando sin cambios.
public final class SupabasePostalCodeRepository: PostalCodeRepository {
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

        var request = URLRequest(
            url: Config.SUPABASE_URL.appendingPathComponent("rest/v1/rpc/lookup_cp")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Config.SUPABASE_ANON_KEY)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(["p_cp": clean])
        // El registro no puede quedarse colgado esperando el C.P.
        request.timeoutInterval = 8

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Sin red / timeout: el servicio no respondió, NO es que el C.P. no exista.
            throw PostalCodeError.serviceUnavailable
        }

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw PostalCodeError.serviceUnavailable
        }

        guard let rows = try? JSONDecoder().decode([Row].self, from: data) else {
            throw PostalCodeError.serviceUnavailable
        }
        // El RPC devuelve `[]` cuando el C.P. no existe en el padrón.
        guard let row = rows.first else { return nil }

        return PostalCodeInfo(
            codigoPostal: clean,
            colonias: row.colonias,
            municipio: row.municipio,
            estado: row.estado
        )
    }

    // Forma de una fila del RPC `lookup_cp`.
    private struct Row: Decodable {
        let estado: String
        let municipio: String
        let ciudad: String?
        let colonias: [String]
    }
}
