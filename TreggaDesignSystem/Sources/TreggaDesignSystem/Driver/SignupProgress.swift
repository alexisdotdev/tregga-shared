import SwiftUI

/// Barra de progreso del flujo signup-correo (driver v3).
/// Muestra `step` de `total` con barras llenas hasta `step`.
public struct SignupProgress: View {
    public let step: Int
    public let total: Int

    public init(step: Int, total: Int = 6) {
        self.step = step
        self.total = total
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < step ? TreggaColors.primary : TreggaColors.surface2)
                        .frame(height: 4)
                }
            }
            Text("Crea tu cuenta · paso \(step) de \(total)")
                .font(.system(size: 11.5, weight: .heavy))
                .tracking(0.3)
                .textCase(.uppercase)
                .foregroundStyle(TreggaColors.textSec)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }
}

#Preview {
    VStack(spacing: 20) {
        SignupProgress(step: 1)
        SignupProgress(step: 3)
        SignupProgress(step: 6)
    }
    .padding()
}
