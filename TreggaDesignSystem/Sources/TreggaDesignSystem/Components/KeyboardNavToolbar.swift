import SwiftUI
import UIKit

// Barra de teclado con iconos PLANOS (↑/↓/✓). iOS 26 dibuja como chips circulares
// "glass" cualquier botón de icono (tanto en la toolbar de SwiftUI como en un
// UIToolbar de UIKit), así que aquí la barra es una UIView propia con UIImageView
// + gestos de tap — que iOS NO estiliza — montada como inputAccessoryView.
//
// La API pública (keyboardNavToolbar / keyboardDismissToolbar) no cambia.

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

// MARK: - La barra (UIView con iconos planos)

final class KbBarView: UIView {
    private let upIcon = UIImageView()
    private let downIcon = UIImageView()
    private let doneIcon = UIImageView()
    private let tint: UIColor

    var onUp: (() -> Void)?
    var onDown: (() -> Void)?
    var onDone: (() -> Void)?

    init(showNav: Bool, tint: UIColor) {
        self.tint = tint
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 46))
        autoresizingMask = .flexibleWidth
        backgroundColor = UIColor { tc in
            tc.userInterfaceStyle == .dark ? UIColor(white: 0.14, alpha: 1) : UIColor(white: 0.97, alpha: 1)
        }

        let hairline = UIView()
        hairline.backgroundColor = .separator
        hairline.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hairline)

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
        addSubview(stack)

        NSLayoutConstraint.activate([
            hairline.topAnchor.constraint(equalTo: topAnchor),
            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 0.5),
            stack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
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
    let canUp: Bool
    let canDown: Bool
    let onUp: () -> Void
    let onDown: () -> Void
    let onDone: () -> Void

    func makeCoordinator() -> KbBarController {
        KbBarController(showNav: showNav, tint: UIColor(TreggaColors.primary))
    }

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let c = context.coordinator
        c.onUp = onUp
        c.onDown = onDown
        c.onDone = onDone
        c.setEnabled(up: canUp, down: canDown)
        DispatchQueue.main.async { c.attach() }
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
                showNav: false, canUp: false, canDown: false,
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
