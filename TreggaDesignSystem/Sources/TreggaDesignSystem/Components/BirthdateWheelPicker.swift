import SwiftUI

/// Selector de fecha de nacimiento con tres ruedas nativas de iOS (día · mes · año)
/// en lugar del `DatePicker` combinado. Evita el default de "1969" (epoch) del
/// `DatePicker` cuando la fecha aún es `nil`: la rueda arranca en `defaultYear`
/// (1990) con una selección concreta que se escribe al binding.
///
/// - El día se ajusta (clamp) a los días válidos del mes/año elegidos.
/// - `maxYear` limita a no permitir fechas futuras (default: año actual).
public struct BirthdateWheelPicker: View {
    @Binding private var date: Date?
    private let minYear: Int
    private let maxYear: Int

    @State private var day: Int
    @State private var month: Int
    @State private var year: Int

    private static let calendar = Calendar(identifier: .gregorian)

    /// Nombres de meses en es-MX, capitalizados ("Enero", … "Diciembre").
    private static let monthNames: [String] = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        return df.standaloneMonthSymbols.map { $0.prefix(1).uppercased() + $0.dropFirst() }
    }()

    public init(
        date: Binding<Date?>,
        defaultYear: Int = 1990,
        minYear: Int = 1920,
        maxYear: Int? = nil
    ) {
        self._date = date
        self.minYear = minYear
        let currentYear = Self.calendar.component(.year, from: Date())
        self.maxYear = maxYear ?? currentYear

        let comps = date.wrappedValue.map {
            Self.calendar.dateComponents([.day, .month, .year], from: $0)
        }
        _day = State(initialValue: comps?.day ?? 1)
        _month = State(initialValue: comps?.month ?? 1)
        _year = State(initialValue: comps?.year ?? defaultYear)
    }

    /// Conveniencia para call sites con `Date` no-opcional (edición de perfil).
    public init(
        date: Binding<Date>,
        defaultYear: Int = 1990,
        minYear: Int = 1920,
        maxYear: Int? = nil
    ) {
        self.init(
            date: Binding<Date?>(
                get: { date.wrappedValue },
                set: { if let v = $0 { date.wrappedValue = v } }
            ),
            defaultYear: defaultYear,
            minYear: minYear,
            maxYear: maxYear
        )
    }

    public var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Picker("Día", selection: $day) {
                    ForEach(1...daysInMonth, id: \.self) { d in
                        Text(String(d)).font(.system(size: 20, weight: .medium)).tag(d)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: geo.size.width * 0.26)
                .clipped()

                Picker("Mes", selection: $month) {
                    ForEach(1...12, id: \.self) { m in
                        Text(Self.monthNames[m - 1]).font(.system(size: 18, weight: .medium)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: geo.size.width * 0.44)
                .clipped()

                Picker("Año", selection: $year) {
                    ForEach(minYear...maxYear, id: \.self) { y in
                        Text(String(y)).font(.system(size: 20, weight: .medium)).tag(y)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: geo.size.width * 0.30)
                .clipped()
            }
        }
        .frame(height: 170)
        .onAppear { if date == nil { commit() } }
        .onChange(of: day) { _, _ in commit() }
        .onChange(of: month) { _, _ in clampDay(); commit() }
        .onChange(of: year) { _, _ in clampDay(); commit() }
    }

    /// Días válidos del mes/año seleccionados (28–31).
    private var daysInMonth: Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        guard let d = Self.calendar.date(from: comps),
              let range = Self.calendar.range(of: .day, in: .month, for: d) else { return 31 }
        return range.count
    }

    /// Si el día quedó fuera del mes (p. ej. 31 → febrero), lo baja al último válido.
    private func clampDay() {
        let maxDay = daysInMonth
        if day > maxDay { day = maxDay }
    }

    private func commit() {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = min(day, daysInMonth)
        if let d = Self.calendar.date(from: comps) { date = d }
    }
}
