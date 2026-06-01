import Foundation

/// Formateo progresivo de teléfonos mexicanos a 10 dígitos.
/// Layout final: `(451) 101 3076`.
/// Soporta input parcial: el formato crece conforme el usuario teclea.
public enum PhoneFormatter {

    /// Formatea una cadena conservando solo los primeros 10 dígitos.
    /// - "" → ""
    /// - "451" → "(451)"
    /// - "451101" → "(451) 101"
    /// - "4511013076" → "(451) 101 3076"
    public static func format(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber).prefix(10)
        let chars = Array(digits)
        switch chars.count {
        case 0: return ""
        case 1...3: return "(\(String(chars))"
        case 4...6:
            return "(\(String(chars[0..<3]))) \(String(chars[3..<chars.count]))"
        default:
            let p1 = String(chars[0..<3])
            let p2 = String(chars[3..<6])
            let p3 = String(chars[6..<chars.count])
            return "(\(p1)) \(p2) \(p3)"
        }
    }

    /// Devuelve solo los dígitos (max 10).
    public static func digits(_ s: String) -> String {
        String(s.filter(\.isNumber).prefix(10))
    }

    /// Convierte 10 dígitos a E.164 mexicano (`+52XXXXXXXXXX`).
    /// Si el input no tiene exactamente 10 dígitos, retorna nil.
    public static func e164MX(_ s: String) -> String? {
        let d = digits(s)
        guard d.count == 10 else { return nil }
        return "+52\(d)"
    }
}
