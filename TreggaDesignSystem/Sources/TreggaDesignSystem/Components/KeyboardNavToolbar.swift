import SwiftUI
import UIKit

// Barra de teclado con iconos PLANOS (↑/↓/✓). iOS 26 dibuja como chips circulares
// "glass" cualquier botón de icono (toolbar de SwiftUI Y UIToolbar de UIKit), así
// que la barra es una UIView propia (inputAccessoryView) con UIImageView + gestos
// de tap, que iOS NO estiliza. El accessory es más alto que la barra visible para
// dejar un hueco entre la barra y el teclado (no queda pegada). La API pública no
// cambia.

// MARK: - First responder actual (truco sendAction)

private extension UIResponder {
    static weak var treggaCurrent: UIResponder?
    static func treggaFindCurrent() -> UIResponder? {
        treggaCurrent = nil
        UIApplication.shared.sendAction(#selector(treggaCaptureSelf), to: nil, from: nil, for: nil)
        return treggaCurrent
    }
    @objc func treggaCaptureSelf() { UIResponder.treggaCurrent = self }
}

// MARK: - La barra (UIView con iconos planos + hueco sobre el teclado)

final class KbBarView: UIView {
    private let upIcon = UIImageView()
    private let downIcon = UIImageView()
    private let doneIcon = UIImageView()
    private let tint: UIColor

    var onUp: (() -> Void)?
    var onDown: (() -> Void)?
    var onDone: (() -> Void)?

    /// Alto de la barra visible (pill de vidrio) y del hueco hacia el teclado.
    private static let barHeight: CGFloat = 48
    private static let gap: CGFloat = 12
    private static let sideMargin: CGFloat = 10

    init(showNav: Bool, tint: UIColor) {
        self.tint = tint
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width,
                                 height: Self.barHeight + Self.gap))
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear   // fondo transparente: la pill de vidrio flota

        // Pill de vidrio (Liquid Glass en iOS 26; material translúcido como fallback).
        let glass = UIVisualEffectView(effect: Self.glassEffect())
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.layer.cornerRadius = Self.barHeight / 2
        glass.layer.cornerCurve = .continuous
        glass.clipsToBounds = true
        addSubview(glass)

        configure(upIcon, "chevron.up", #selector(tapUp))
        configure(downIcon, "chevron.down", #selector(tapDown))
        configure(doneIcon, "checkmark", #selector(tapDone))

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let arranged = showNav ? [upIcon, downIcon, spacer, doneIcon] : [spacer, doneIcon]
        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.sideMargin),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.sideMargin),
            glass.heightAnchor.constraint(equalToConstant: Self.barHeight),

            stack.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: glass.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: glass.contentView.bottomAnchor),
        ])
    }

    private static func glassEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            return UIGlassEffect()
        } else {
            return UIBlurEffect(style: .systemThinMaterial)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configure(_ iv: UIImageView, _ symbol: String, _ action: Selector) {
        iv.image = UIImage(systemName: symbol,
                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        iv.tintColor = tint
        iv.contentMode = .center
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 40).isActive = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
    }

    @objc private func tapUp() { onUp?() }
    @objc private func tapDown() { onDown?() }
    @objc private func tapDone() { onDone?() }

    func setEnabled(up: Bool, down: Bool) {
        upIcon.alpha = up ? 1 : 0.3
        upIcon.isUserInteractionEnabled = up
        downIcon.alpha = down ? 1 : 0.3
        downIcon.isUserInteractionEnabled = down
    }
}

// MARK: - Controlador (mantiene la barra y la asigna al campo en foco)

final class KbBarController: NSObject {
    let bar: KbBarView

    init(showNav: Bool, tint: UIColor) {
        bar = KbBarView(showNav: showNav, tint: tint)
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
    }

    var onUp: (() -> Void)? { get { bar.onUp } set { bar.onUp = newValue } }
    var onDown: (() -> Void)? { get { bar.onDown } set { bar.onDown = newValue } }
    var onDone: (() -> Void)? { get { bar.onDone } set { bar.onDone = newValue } }

    func setEnabled(up: Bool, down: Bool) { bar.setEnabled(up: up, down: down) }

    @objc private func keyboardWillShow() {
        DispatchQueue.main.async { [weak self] in self?.attach() }
    }

    /// Asigna esta barra como inputAccessoryView del campo en foco. Idempotente:
    /// no recarga si ya está puesta (evita el parpadeo al escribir).
    func attach() {
        guard let field = UIResponder.treggaFindCurrent() else { return }
        if let tf = field as? UITextField, tf.inputAccessoryView !== bar {
            tf.inputAccessoryView = bar; tf.reloadInputViews()
        } else if let tv = field as? UITextView, tv.inputAccessoryView !== bar {
            tv.inputAccessoryView = bar; tv.reloadInputViews()
        }
    }
}

// MARK: - Representable que hospeda el controlador

private struct KbBarAttacher: UIViewRepresentable {
    let showNav: Bool
    let focusToken: AnyHashable?
    let canUp: Bool
    let canDown: Bool
    let onUp: () -> Void
    let onDown: () -> Void
    let onDone: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: KbBarController(showNav: showNav, tint: UIColor(TreggaColors.primary)))
    }

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let c = context.coordinator.controller
        c.onUp = onUp
        c.onDown = onDown
        c.onDone = onDone
        c.setEnabled(up: canUp, down: canDown)
        // Re-asignar la barra SOLO al cambiar de campo (no en cada tecla → sin parpadeo).
        if focusToken != context.coordinator.lastToken {
            context.coordinator.lastToken = focusToken
            DispatchQueue.main.async { c.attach() }
        }
    }

    final class Coordinator {
        let controller: KbBarController
        var lastToken: AnyHashable?
        init(controller: KbBarController) { self.controller = controller }
    }
}

// MARK: - API pública (sin cambios para los call sites)

public extension View {
    /// Barra sobre el teclado con flechas ↑/↓ para moverse entre los campos del
    /// formulario y un check (✓) para ocultarlo. Iconos planos (UIKit).
    ///
    /// Uso:
    /// ```
    /// enum Campo { case correo, password }
    /// @FocusState private var foco: Campo?
    /// ...
    /// TextField(...).focused($foco, equals: .correo)
    /// .keyboardNavToolbar($foco, order: [.correo, .password])
    /// ```
    func keyboardNavToolbar<Field: Hashable>(
        _ focus: FocusState<Field?>.Binding,
        order: [Field]
    ) -> some View {
        let idx = focus.wrappedValue.flatMap { order.firstIndex(of: $0) }
        return background(
            KbBarAttacher(
                showNav: true,
                focusToken: focus.wrappedValue.map { AnyHashable($0) },
                canUp: (idx ?? 0) > 0,
                canDown: idx != nil && idx! < order.count - 1,
                onUp: { if let i = idx, i > 0 { focus.wrappedValue = order[i - 1] } },
                onDown: { if let i = idx, i < order.count - 1 { focus.wrappedValue = order[i + 1] } },
                onDone: { focus.wrappedValue = nil }
            )
        )
    }

    /// Versión simple para pantallas de un solo campo: solo el check (✓) plano.
    func keyboardDismissToolbar() -> some View {
        background(
            KbBarAttacher(
                showNav: false, focusToken: nil, canUp: false, canDown: false,
                onUp: {}, onDown: {},
                onDone: {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                }
            )
        )
    }
}
