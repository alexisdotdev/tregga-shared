import Foundation

/// Validador de CURP mexicano (Fase A — solo formato + dígito verificador).
///
/// Valida que el CURP cumpla:
/// 1. **Formato** — 18 caracteres en el patrón oficial RENAPO
///    (4 letras + 6 dígitos + H/M + 2 letras entidad + 3 consonantes + carácter + dígito).
/// 2. **Dígito verificador** — el último carácter es un checksum determinístico
///    de los 17 anteriores (algoritmo oficial RENAPO).
///
/// NO verifica que la persona realmente exista en RENAPO. Esa validación
/// requiere integración externa (Truora, MetaMap, etc.) y se hará en Fase B.
public enum CURPValidator {

    /// Devuelve true si la cadena es un CURP válido en formato y checksum.
    public static func isValid(_ input: String) -> Bool {
        let curp = normalize(input)
        guard curp.count == 18 else { return false }
        guard curp.range(of: pattern, options: .regularExpression) != nil else { return false }
        return checksum(curp) == curp.last!
    }

    /// Normaliza a uppercase + trim. No modifica si ya está limpio.
    public static func normalize(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Calcula el dígito verificador (posición 18) a partir de las primeras 17 posiciones.
    /// Algoritmo oficial RENAPO: cada valor se multiplica por `18 - i` (con i 0-based),
    /// es decir multiplicadores 18, 17, …, 2 para las posiciones 1..17.
    /// Luego (10 − (suma mod 10)) mod 10 = dígito verificador.
    public static func checksum(_ curp: String) -> Character {
        let chars = Array(curp.uppercased())
        guard chars.count >= 17 else { return "0" }
        var suma = 0
        for i in 0..<17 {
            let valor = alphabetValue[chars[i]] ?? 0
            suma += valor * (18 - i)
        }
        let mod = suma % 10
        let resultado = (10 - mod) % 10
        return Character("\(resultado)")
    }

    /// Verifica que el bloque de fecha del CURP (posiciones 5-10 = aaMMdd) coincida
    /// con la `fechaNacimiento` capturada en pantalla. El siglo se infiere de la
    /// posición 17: dígito = 1900s, letra = 2000s (regla oficial RENAPO).
    /// Útil como cross-check para atrapar typos cruzados entre campos.
    public static func matchesBirthDate(_ input: String, fechaNacimiento: Date) -> Bool {
        let curp = normalize(input)
        guard curp.count == 18 else { return false }
        let chars = Array(curp)
        let yyStr = String(chars[4...5])
        let mmStr = String(chars[6...7])
        let ddStr = String(chars[8...9])
        let position17 = chars[16]
        guard let yy = Int(yyStr), let mm = Int(mmStr), let dd = Int(ddStr) else { return false }
        let year = position17.isLetter ? 2000 + yy : 1900 + yy

        var comps = DateComponents()
        comps.year = year
        comps.month = mm
        comps.day = dd
        let calendar = Calendar(identifier: .gregorian)
        guard let curpDate = calendar.date(from: comps) else { return false }

        let curpYMD = calendar.dateComponents([.year, .month, .day], from: curpDate)
        let fechaYMD = calendar.dateComponents([.year, .month, .day], from: fechaNacimiento)
        return curpYMD.year == fechaYMD.year
            && curpYMD.month == fechaYMD.month
            && curpYMD.day == fechaYMD.day
    }

    /// Patrón regex del CURP. Ver https://www.gob.mx/curp.
    /// Posiciones (1-based):
    ///  1: 1ª letra apellido paterno (A-Z)
    ///  2: 1ª vocal interna apellido paterno (A/E/I/O/U/X — X para casos sin vocal)
    ///  3: 1ª letra apellido materno (A-Z)
    ///  4: 1ª letra del nombre (A-Z)
    ///  5-10: fecha aaMMdd
    ///  11: H (hombre) o M (mujer)
    ///  12-13: clave de la entidad federativa
    ///  14: 1ª consonante interna apellido paterno
    ///  15: 1ª consonante interna apellido materno
    ///  16: 1ª consonante interna nombre
    ///  17: 0-9 (nacidos antes de 2000) o A-Z (después)
    ///  18: dígito verificador
    private static let pattern = #"^[A-Z][AEIOUX][A-Z]{2}\d{6}[HM][A-Z]{2}[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z]\d$"#

    /// Mapeo carácter → valor numérico para el checksum.
    /// 0-9 = 0-9; A-N = 10-23; Ñ = 24; O-Z = 25-36.
    private static let alphabetValue: [Character: Int] = {
        var dict: [Character: Int] = [:]
        for c in "0123456789" { dict[c] = Int(String(c))! }
        let letras = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"
        for (i, c) in letras.enumerated() { dict[c] = i + 10 }
        return dict
    }()
}
