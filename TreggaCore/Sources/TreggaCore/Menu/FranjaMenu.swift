import Foundation

/// Franja del día en que un platillo se sirve. La lista de franjas de un producto
/// vacía significa "todo el día". Fuente de verdad compartida entre Business (que
/// las edita) y Food (que las hace cumplir), para que ambos coincidan.
public enum FranjaMenu: String, CaseIterable, Sendable, Codable {
    case desayuno
    case comida
    case cena

    /// Etiqueta corta para chips/labels.
    public var etiqueta: String {
        switch self {
        case .desayuno: return "Desayuno"
        case .comida:   return "Comida"
        case .cena:     return "Cena"
        }
    }

    /// Momento del día en lenguaje natural ("Disponible en la mañana").
    public var momento: String {
        switch self {
        case .desayuno: return "la mañana"
        case .comida:   return "la tarde"
        case .cena:     return "la noche"
        }
    }

    /// Rango por defecto en minutos desde medianoche (editable por negocio).
    public var rangoDefault: FranjaRango {
        switch self {
        case .desayuno: return FranjaRango(inicio: 6 * 60, fin: 12 * 60)   // 06:00–12:00
        case .comida:   return FranjaRango(inicio: 12 * 60, fin: 18 * 60)  // 12:00–18:00
        case .cena:     return FranjaRango(inicio: 18 * 60, fin: 23 * 60 + 59) // 18:00–23:59
        }
    }
}

/// Rango horario expresado en minutos desde medianoche (hora local).
public struct FranjaRango: Equatable, Sendable, Codable {
    public var inicio: Int
    public var fin: Int

    public init(inicio: Int, fin: Int) {
        self.inicio = inicio
        self.fin = fin
    }

    /// Soporta rangos que cruzan medianoche (p. ej. cena 20:00–02:00).
    public func contiene(minuto: Int) -> Bool {
        if inicio <= fin { return minuto >= inicio && minuto < fin }
        return minuto >= inicio || minuto < fin
    }

    public var inicioTexto: String { FranjaRango.hhmm(inicio) }
    public var finTexto: String { FranjaRango.hhmm(fin) }

    public static func hhmm(_ m: Int) -> String {
        let mm = ((m % (24 * 60)) + 24 * 60) % (24 * 60)
        return String(format: "%02d:%02d", mm / 60, mm % 60)
    }

    /// Parsea "HH:MM" a minutos desde medianoche. Devuelve nil si no es válido.
    public static func minutos(desde texto: String) -> Int? {
        let partes = texto.split(separator: ":")
        guard partes.count == 2, let h = Int(partes[0]), let m = Int(partes[1]),
              (0...23).contains(h), (0...59).contains(m) else { return nil }
        return h * 60 + m
    }
}

/// Rangos horarios de las tres franjas de un negocio. Si una franja no está
/// configurada, se usa su `rangoDefault`.
public struct FranjasHorario: Equatable, Sendable {
    public var rangos: [FranjaMenu: FranjaRango]

    public init(rangos: [FranjaMenu: FranjaRango] = [:]) {
        self.rangos = rangos
    }

    public static var porDefecto: FranjasHorario {
        FranjasHorario(rangos: Dictionary(uniqueKeysWithValues: FranjaMenu.allCases.map { ($0, $0.rangoDefault) }))
    }

    public func rango(_ f: FranjaMenu) -> FranjaRango {
        rangos[f] ?? f.rangoDefault
    }

    /// Construye desde el jsonb de `negocios.franjas_horario`
    /// (`{"desayuno":{"inicio":"HH:MM","fin":"HH:MM"},...}`). Campos faltantes/
    /// inválidos caen al default de cada franja.
    public static func desdeJSON(_ json: [String: [String: String]]?) -> FranjasHorario {
        guard let json else { return .porDefecto }
        var rangos: [FranjaMenu: FranjaRango] = [:]
        for f in FranjaMenu.allCases {
            if let par = json[f.rawValue],
               let i = par["inicio"].flatMap(FranjaRango.minutos(desde:)),
               let fin = par["fin"].flatMap(FranjaRango.minutos(desde:)) {
                rangos[f] = FranjaRango(inicio: i, fin: fin)
            } else {
                rangos[f] = f.rangoDefault
            }
        }
        return FranjasHorario(rangos: rangos)
    }

    /// Serializa al shape jsonb que guarda `negocios.franjas_horario`.
    public func aJSON() -> [String: [String: String]] {
        var out: [String: [String: String]] = [:]
        for f in FranjaMenu.allCases {
            let r = rango(f)
            out[f.rawValue] = ["inicio": r.inicioTexto, "fin": r.finTexto]
        }
        return out
    }

    /// Franjas activas en un momento dado (por minuto del día local).
    public func franjasActivas(minutoDelDia: Int) -> Set<FranjaMenu> {
        Set(FranjaMenu.allCases.filter { rango($0).contiene(minuto: minutoDelDia) })
    }
}

/// Cálculo de disponibilidad por franja, compartido entre apps.
public enum DisponibilidadMenu {

    /// Minuto del día (0–1439) de `fecha` en el calendario dado.
    public static func minutoDelDia(_ fecha: Date = Date(), calendario: Calendar = .current) -> Int {
        let c = calendario.dateComponents([.hour, .minute], from: fecha)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// `franjas` vacío = todo el día (siempre disponible). Si no, disponible cuando
    /// la hora actual cae dentro de alguna de sus franjas.
    public static func disponibleAhora(
        franjas: [String],
        horario: FranjasHorario,
        ahora: Date = Date(),
        calendario: Calendar = .current
    ) -> Bool {
        let fs = franjas.compactMap { FranjaMenu(rawValue: $0) }
        guard !fs.isEmpty else { return true }
        let minuto = minutoDelDia(ahora, calendario: calendario)
        return fs.contains { horario.rango($0).contiene(minuto: minuto) }
    }

    /// Etiqueta legible de las franjas de un producto ("Todo el día", "Desayuno · Cena").
    public static func etiqueta(franjas: [String]) -> String {
        let fs = FranjaMenu.allCases.filter { franjas.contains($0.rawValue) }
        guard !fs.isEmpty else { return "Todo el día" }
        return fs.map(\.etiqueta).joined(separator: " · ")
    }

    /// Texto para el cliente cuando un platillo no está en su franja
    /// ("Disponible en la mañana"). Usa la primera franja del producto.
    public static func textoNoDisponible(franjas: [String]) -> String {
        guard let f = FranjaMenu.allCases.first(where: { franjas.contains($0.rawValue) }) else {
            return "No disponible ahora"
        }
        return "Disponible en \(f.momento)"
    }
}
