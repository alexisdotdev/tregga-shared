import Foundation

/// Requisitos de contraseña. **Espejo exacto de lo que exige Supabase Auth.**
///
/// El panel del proyecto está configurado con `Minimum password length = 8` y
/// `Password requirements = "Lowercase, upper... "` → en realidad **"Letters and
/// digits"**: la contraseña debe tener al menos una letra y al menos un dígito.
/// Esto reproduce esa regla y nada más.
///
/// ## Por qué vive aquí y no en cada app
///
/// Estaba escrita cuatro veces —Delivery (lista + gate), Food (lista + gate, en
/// dos ficheros distintos) y Business— y las cuatro pedían **una mayúscula**, que
/// el servidor NO exige. La web además pedía minúscula. Tres capas, tres reglas
/// distintas: alguien se registraba en la app con `TREGGA2026` y luego la web le
/// rechazaba ese mismo estilo al cambiarla.
///
/// ## La regla de oro al tocar esto
///
/// Añadir un requisito aquí **sin cambiarlo también en el panel de Supabase**
/// vuelve a crear la mentira, solo que al revés: la app enseñaría palomitas
/// verdes y el servidor rechazaría igual. Y quitarlo sin tocar el panel deja al
/// usuario chocando contra un error que la pantalla no le anticipó.
///
/// El servidor es el único que no se puede saltar. Esto solo lo **refleja**.
public enum PasswordRules {

    public static let longitudMinima = 8

    /// Los requisitos en el orden en que se le muestran al usuario. Es la MISMA
    /// fuente para la lista de la UI y para el gate del botón, a propósito: en
    /// Delivery ya se habían desincronizado una vez y la pantalla enseñaba una ✗
    /// en un requisito que no bloqueaba nada.
    public static func requisitos(_ password: String) -> [(label: String, ok: Bool)] {
        [
            ("\(longitudMinima)+ caracteres", password.count >= longitudMinima),
            ("Una letra", password.contains(where: \.isLetter)),
            ("Un número", password.contains(where: \.isNumber)),
        ]
    }

    public static func isValid(_ password: String) -> Bool {
        requisitos(password).allSatisfy(\.ok)
    }

    /// Texto de una línea para placeholders y avisos, derivado de la misma regla
    /// para que no pueda contradecirla.
    public static let resumen = "Mínimo \(longitudMinima) caracteres, con letras y números"
}
