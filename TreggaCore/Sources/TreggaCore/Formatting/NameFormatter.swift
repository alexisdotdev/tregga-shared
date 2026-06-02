import Foundation

/// Capitalización de nombres/apellidos al estilo de las apps Tregga.
/// Complementa `.textInputAutocapitalization(.words)` (que solo es una pista del
/// teclado y no aplica con teclado físico/pegado): fuerza la primera letra de
/// cada palabra en mayúscula conservando el resto del texto y la longitud, para
/// que el cursor no salte al escribir.
public enum NameFormatter {
    /// "juan ramírez" → "Juan Ramírez". No baja a minúsculas el resto de cada
    /// palabra (respeta "McDonald", iniciales, etc.). Conserva espacios.
    public static func capitalizedWords(_ raw: String) -> String {
        raw.split(separator: " ", omittingEmptySubsequences: false)
            .map { word -> String in
                guard let first = word.first else { return String(word) }
                return first.uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }
}
