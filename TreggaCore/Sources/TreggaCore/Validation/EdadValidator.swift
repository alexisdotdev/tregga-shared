import Foundation

/// Validación de mayoría de edad (spec §4 — 18+).
public enum EdadValidator {

    /// Indica si la fecha de nacimiento es de hace 18+ años respecto a `now`.
    public static func esMayorDe18(fechaNacimiento: Date, now: Date = Date()) -> Bool {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year], from: fechaNacimiento, to: now)
        return (comps.year ?? 0) >= 18
    }
}
