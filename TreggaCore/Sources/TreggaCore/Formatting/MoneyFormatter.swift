import Foundation

/// Formateo de moneda al estilo jQuery Mask Money: el usuario teclea solo dígitos
/// y el valor crece desde los centavos. Ej.:
/// - "" → "$0.00"
/// - "1" → "$0.01"
/// - "12" → "$0.12"
/// - "123" → "$1.23"
/// - "123456" → "$1,234.56"
///
/// Por default usa locale `es_MX` (peso mexicano `$` + thousands `,` + decimal `.`).
public enum MoneyFormatter {

    /// Estado interno = `Int` de centavos. Conviértelo a pesos dividiendo entre 100.
    public static func centavos(from raw: String) -> Int {
        let digits = raw.filter(\.isNumber).prefix(12)  // ~$9.9B max
        return Int(String(digits)) ?? 0
    }

    /// Convierte centavos a string formateado.
    public static func format(centavos: Int, locale: Locale = Locale(identifier: "es_MX")) -> String {
        let pesos = Decimal(centavos) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: pesos)) ?? "$0.00"
    }

    /// Convenience: re-formatea la cadena (parsea dígitos, calcula centavos, formatea).
    public static func format(_ raw: String, locale: Locale = Locale(identifier: "es_MX")) -> String {
        format(centavos: centavos(from: raw), locale: locale)
    }

    /// Convierte centavos a `Decimal` de pesos.
    public static func pesos(centavos: Int) -> Decimal {
        Decimal(centavos) / 100
    }

    /// Convierte un `Decimal` de pesos a centavos (redondea al entero más cercano).
    public static func centavos(pesos: Decimal) -> Int {
        let mult = pesos * 100
        var rounded = Decimal()
        var source = mult
        NSDecimalRound(&rounded, &source, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
