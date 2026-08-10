import Foundation

/// Categoría de negocio del ecosistema Tregga (comida MX).
///
/// Lista canónica compartida: **Business** la usa como selector al registrar
/// (en vez de texto libre, que producía typos como "Creperia") y **Food** puede
/// agrupar/filtrar negocios por ella. El valor que se guarda en `negocios.tipo`
/// es `label` (el texto visible), no un slug: así las filas existentes con texto
/// libre siguen funcionando y Food no necesita migración ni un mapa slug→texto.
public struct BusinessCategory: Identifiable, Hashable, Sendable {
    /// Slug estable (uso interno/analytics); NO es lo que se guarda en la DB.
    public let id: String
    /// Texto visible (es-MX). **Este** es el valor que se persiste en `tipo`.
    public let label: String
    /// Emoji para el chip del selector y las tarjetas de Food.
    public let emoji: String

    public init(id: String, label: String, emoji: String) {
        self.id = id
        self.label = label
        self.emoji = emoji
    }
}

public extension BusinessCategory {
    /// Catálogo curado (26) estilo Rappi/UberEats/DiDi Food para MX (solo comida).
    static let all: [BusinessCategory] = [
        .init(id: "tacos",          label: "Tacos",                  emoji: "🌮"),
        .init(id: "hamburguesas",   label: "Hamburguesas",           emoji: "🍔"),
        .init(id: "pizza",          label: "Pizza",                  emoji: "🍕"),
        .init(id: "sushi",          label: "Sushi / Japonesa",       emoji: "🍣"),
        .init(id: "mariscos",       label: "Mariscos",               emoji: "🦐"),
        .init(id: "pollo",          label: "Pollo / Rostizado",      emoji: "🍗"),
        .init(id: "antojitos",      label: "Antojitos mexicanos",    emoji: "🫔"),
        .init(id: "tortas",         label: "Tortas / Sándwiches",    emoji: "🥪"),
        .init(id: "corrida",        label: "Comida corrida / Económica", emoji: "🍲"),
        .init(id: "desayunos",      label: "Desayunos",              emoji: "🍳"),
        .init(id: "cafe",           label: "Café / Cafetería",       emoji: "☕️"),
        .init(id: "postres",        label: "Postres / Repostería",   emoji: "🍰"),
        .init(id: "crepas",         label: "Crepas / Waffles",       emoji: "🧇"),
        .init(id: "helados",        label: "Helados / Nieves",       emoji: "🍦"),
        .init(id: "saludable",      label: "Saludable / Ensaladas",  emoji: "🥗"),
        .init(id: "vegana",         label: "Vegana / Vegetariana",   emoji: "🌱"),
        .init(id: "panaderia",      label: "Panadería / Pastelería", emoji: "🥐"),
        .init(id: "jugos",          label: "Jugos / Smoothies",      emoji: "🥤"),
        .init(id: "alitas",         label: "Alitas / Boneless",      emoji: "🍗"),
        .init(id: "birria",         label: "Birria / Barbacoa",      emoji: "🍖"),
        .init(id: "pozole",         label: "Pozole / Caldos",        emoji: "🥣"),
        .init(id: "parrilla",       label: "Parrilla / Carnes",      emoji: "🥩"),
        .init(id: "pastas",         label: "Pastas / Italiana",      emoji: "🍝"),
        .init(id: "hotdogs",        label: "Hot dogs",               emoji: "🌭"),
        .init(id: "bebidas",        label: "Bebidas",                emoji: "🧃"),
        .init(id: "otro",           label: "Otro",                   emoji: "🍽️")
    ]

    /// Resuelve una categoría a partir del `tipo` guardado, sin distinguir
    /// mayúsculas/acentos. Primero intenta match exacto con el label (lo que
    /// guarda el selector nuevo); si no, hace un fallback por palabra clave para
    /// clasificar los `tipo` de texto libre previos al selector
    /// (p. ej. "Tacos · Antojitos" → Tacos). Devuelve nil si no encaja en ninguna.
    static func resolve(_ tipo: String?) -> BusinessCategory? {
        guard let tipo, !tipo.isEmpty else { return nil }
        let normTipo = norm(tipo)
        if let exacta = all.first(where: { norm($0.label) == normTipo }) { return exacta }
        // Fallback: una palabra (≥4 letras) del label aparece como token del tipo.
        let tokens = Set(palabras(normTipo))
        guard !tokens.isEmpty else { return nil }
        return all.first { cat in
            palabras(norm(cat.label)).contains { tokens.contains($0) }
        }
    }

    private static func norm(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    /// Tokens significativos (≥4 letras) de un texto ya normalizado.
    private static func palabras(_ normalizado: String) -> [String] {
        normalizado.split { !$0.isLetter }.map(String.init).filter { $0.count >= 4 }
    }
}
