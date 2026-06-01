import Foundation

/// Validación y formato de teléfonos MX para Tregga Delivery (spec §4).
///
/// Input del usuario: 10 dígitos (`4431234567`).
/// Formato E.164 para Supabase Phone Auth: `+52` + 10 dígitos.
public enum PhoneValidator {

    /// Verifica que la cadena tenga exactamente 10 dígitos numéricos.
    public static func isValid10Digits(_ input: String) -> Bool {
        let digits = soloDigitos(from: input)
        return digits.count == 10 && digits.allSatisfy(\.isNumber)
    }

    /// Quita todo lo que no sea dígito.
    public static func soloDigitos(from input: String) -> String {
        input.filter(\.isNumber)
    }

    /// Convierte input de 10 dígitos a formato E.164 +52XXXXXXXXXX.
    public static func formatE164(from tenDigits: String) -> String {
        "+52" + soloDigitos(from: tenDigits)
    }

    /// Convierte hasta 10 dígitos a máscara visual "XXX XXX XXXX".
    public static func mascaraVisual(from input: String) -> String {
        let d = soloDigitos(from: input)
        switch d.count {
        case 0...3:
            return d
        case 4...6:
            return "\(d.prefix(3)) \(d.dropFirst(3))"
        default:
            let p1 = d.prefix(3)
            let p2 = d.dropFirst(3).prefix(3)
            let p3 = d.dropFirst(6).prefix(4)
            return "\(p1) \(p2) \(p3)"
        }
    }
}
