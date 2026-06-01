import SwiftUI

/// Bottom-sheet de confirmación de cierre de sesión, compartido por las apps Tregga.
/// Fondo oscurecido + tarjeta inferior con icono, título, descripción y botones
/// Cancelar / Cerrar sesión (rojo).
public struct LogoutConfirmDialog: View {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    var message: String

    public init(
        isPresented: Binding<Bool>,
        message: String = "Tendrás que volver a iniciar sesión con tu teléfono y código SMS la próxima vez.",
        onConfirm: @escaping () -> Void = {}
    ) {
        self._isPresented = isPresented
        self.message = message
        self.onConfirm = onConfirm
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) { isPresented = false }
                }

            VStack(spacing: 0) {
                handleBar

                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: TreggaRadius.lg)
                            .fill(TreggaColors.surface)
                            .frame(width: 56, height: 56)
                        TreggaIcon(.user, size: 26, color: TreggaColors.text)
                    }

                    Text("¿Cerrar sesión?")
                        .treggaStyle(.h2)
                        .foregroundStyle(TreggaColors.text)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(TreggaColors.textSec)
                        .multilineTextAlignment(.center)
                        .lineSpacing(14 * 0.5)
                }
                .padding(.horizontal, 22)

                Spacer().frame(height: 20)

                HStack(spacing: 10) {
                    TreggaButton(
                        "Cancelar",
                        kind: .ghost,
                        isFullWidth: false,
                        height: 52,
                        action: {
                            withAnimation(.easeInOut(duration: 0.25)) { isPresented = false }
                        }
                    )
                    .frame(maxWidth: .infinity)

                    Button {
                        onConfirm()
                        withAnimation(.easeInOut(duration: 0.25)) { isPresented = false }
                    } label: {
                        Text("Cerrar sesión")
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(TreggaColors.danger)
                            .clipShape(RoundedRectangle(cornerRadius: TreggaRadius.lg))
                            .shadow(color: TreggaColors.danger.opacity(0.32), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 40)
            }
            .padding(.top, 20)
            .background(TreggaColors.bg)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: TreggaRadius.huge,
                topTrailingRadius: TreggaRadius.huge
            ))
            .transition(.move(edge: .bottom))
        }
        .ignoresSafeArea()
    }

    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(TreggaColors.border)
            .frame(width: 40, height: 4)
            .padding(.bottom, 16)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        LogoutConfirmDialog(isPresented: .constant(true))
    }
}
