import Foundation

/// Validación de código postal mexicano (spec §4).
public enum CPValidator {
    public static func isValid(_ input: String) -> Bool {
        input.count == 5 && input.allSatisfy(\.isNumber)
    }
}
