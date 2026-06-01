import SwiftUI

/// 4-step progress bar used across the trip flow.
///
/// Used in: To Restaurant, Pickup, To Customer, Confirm Delivery.
public struct DStepProgress: View {
    let labels: [String]
    let currentIndex: Int

    public init(labels: [String], currentIndex: Int) {
        self.labels = labels
        self.currentIndex = currentIndex
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(labels.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentIndex ? TreggaColors.primary : TreggaColors.surface2)
                        .frame(height: 4)
                }
            }
            HStack(spacing: 4) {
                ForEach(labels.indices, id: \.self) { i in
                    Text(labels[i])
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(0.1)
                        .foregroundStyle(i <= currentIndex ? TreggaColors.text : TreggaColors.textTer)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview("DStepProgress") {
    VStack(spacing: 24) {
        DStepProgress(labels: ["Recoger", "Confirmar", "Entregar", "Listo"], currentIndex: 0)
        DStepProgress(labels: ["Recoger", "Confirmar", "Entregar", "Listo"], currentIndex: 1)
        DStepProgress(labels: ["Recoger", "Confirmar", "Entregar", "Listo"], currentIndex: 2)
        DStepProgress(labels: ["Recoger", "Confirmar", "Entregar", "Listo"], currentIndex: 3)
    }
    .padding(20)
    .background(TreggaColors.bg)
}
