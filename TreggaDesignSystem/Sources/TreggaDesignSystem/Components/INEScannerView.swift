import SwiftUI
import AVFoundation
import Vision
import UIKit

/// Escáner de credencial (INE) con detección en vivo de rectángulo (Vision).
/// Dibuja un marco con forma de tarjeta; cuando la credencial queda bien
/// alineada el marco se pone **verde** y la foto se toma sola (auto-captura),
/// con corrección de perspectiva. Siempre hay botón manual de disparo como
/// respaldo. Pensado para INE frente/reverso; reutilizable en Business/Delivery.
///
/// Requiere `NSCameraUsageDescription` en el Info.plist del host. La cámara no
/// existe en el simulador → ahí muestra un aviso y solo permite cancelar.
public struct INEScannerView: UIViewControllerRepresentable {
    private let title: String
    private let onCapture: (UIImage) -> Void
    private let onCancel: () -> Void

    public init(
        title: String = "Coloca tu INE dentro del marco",
        onCapture: @escaping (UIImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.onCapture = onCapture
        self.onCancel = onCancel
    }

    public func makeUIViewController(context: Context) -> INEScannerController {
        let c = INEScannerController()
        c.titleText = title
        c.onCapture = onCapture
        c.onCancel = onCancel
        return c
    }

    public func updateUIViewController(_ uiViewController: INEScannerController, context: Context) {}
}

/// Resultado de un frame procesado por Vision (en coordenadas normalizadas
/// Vision, origen abajo-izquierda, espacio ya en orientación portrait).
private struct FrameResult {
    let box: CGRect?          // boundingBox de la observación
    let aligned: Bool
    let focused: Bool         // cámara con enfoque estable (no "hunting")
}

/// Procesa frames fuera del main thread y devuelve callbacks ya en main.
private final class RectProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    /// Rect guía en coordenadas normalizadas (origen abajo-izquierda) contra el
    /// que se valida la alineación. Lo fija el controller según el tamaño real.
    var guideNormalized: CGRect = CGRect(x: 0.08, y: 0.34, width: 0.84, height: 0.32)
    var onResult: ((FrameResult) -> Void)?
    var onAutoCapture: ((UIImage) -> Void)?
    /// Cámara activa: se consulta `isAdjustingFocus` para no capturar borroso.
    weak var device: AVCaptureDevice?
    /// Última caja del documento detectada en vivo (normalizada, origen abajo-izq).
    /// La usa el recorte de la foto, ya que el buffer de video y la foto comparten
    /// encuadre y orientación.
    private(set) var lastBox: CGRect?

    private let ciContext = CIContext()
    private var alignedStreak = 0
    private var didCapture = false
    private var latestBuffer: CVPixelBuffer?
    private var latestObs: VNRectangleObservation?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        latestBuffer = pb

        // Detector dedicado a documentos/credenciales (iOS 15+): mucho más fiable
        // que VNDetectRectangles para una INE (tolera luz, perspectiva y bordes
        // suaves). Devuelve igualmente un VNRectangleObservation con las esquinas.
        let request = VNDetectDocumentSegmentationRequest()

        // El connection se fuerza a portrait → la imagen ya viene derecha (.up).
        let handler = VNImageRequestHandler(cvPixelBuffer: pb, orientation: .up, options: [:])
        try? handler.perform([request])
        let obs = request.results?.first
        latestObs = obs
        lastBox = obs?.boundingBox

        // Sin auto-captura: solo damos feedback (marco verde) cuando está bien
        // encuadrada y enfocada. El usuario decide cuándo disparar con el botón.
        let aligned = obs.map { $0.confidence >= 0.5 && isAligned($0.boundingBox) } ?? false
        let focused = !(device?.isAdjustingFocus ?? false)

        let result = FrameResult(box: obs?.boundingBox, aligned: aligned, focused: focused)
        DispatchQueue.main.async { self.onResult?(result) }
    }

    /// Marca el inicio de captura (disparo manual). Devuelve false si ya se está
    /// capturando, para no disparar la foto dos veces.
    func beginCapture() -> Bool {
        guard !didCapture else { return false }
        didCapture = true
        return true
    }

    /// Reinicia el estado para volver a capturar (al pulsar "Volver a tomar").
    func reset() {
        didCapture = false
        alignedStreak = 0
    }

    /// Alineado = el documento detectado llena buena parte del encuadre y está
    /// razonablemente centrado. Se basa en ÁREA + centro (invariante a la
    /// orientación del buffer), no en calzar exacto contra la guía: así el verde
    /// y la auto-captura disparan de forma fiable aunque el buffer venga rotado.
    private func isAligned(_ box: CGRect) -> Bool {
        let area = box.width * box.height
        let centered = abs(box.midX - 0.5) < 0.22 && abs(box.midY - 0.5) < 0.22
        return area >= 0.16 && centered
    }

    private func crop(_ pb: CVPixelBuffer, _ obs: VNRectangleObservation) -> UIImage {
        let ci = CIImage(cvPixelBuffer: pb)
        let w = ci.extent.width, h = ci.extent.height
        func v(_ p: CGPoint) -> CIVector { CIVector(x: p.x * w, y: p.y * h) }
        guard let f = CIFilter(name: "CIPerspectiveCorrection") else { return fullFrame(pb) }
        f.setValue(ci, forKey: kCIInputImageKey)
        f.setValue(v(obs.topLeft), forKey: "inputTopLeft")
        f.setValue(v(obs.topRight), forKey: "inputTopRight")
        f.setValue(v(obs.bottomLeft), forKey: "inputBottomLeft")
        f.setValue(v(obs.bottomRight), forKey: "inputBottomRight")
        let out = f.outputImage ?? ci
        guard let cg = ciContext.createCGImage(out, from: out.extent) else { return fullFrame(pb) }
        return UIImage(cgImage: cg)
    }

    private func fullFrame(_ pb: CVPixelBuffer) -> UIImage {
        let ci = CIImage(cvPixelBuffer: pb)
        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return UIImage() }
        return UIImage(cgImage: cg)
    }
}

public final class INEScannerController: UIViewController, AVCapturePhotoCaptureDelegate {
    var titleText: String = ""
    var onCapture: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let processor = RectProcessor()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "app.tregga.ine-scanner.session")
    private let videoQueue = DispatchQueue(label: "app.tregga.ine-scanner.video")
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let dimLayer = CAShapeLayer()
    private let guideLayer = CAShapeLayer()
    private let titleLabel = UILabel()
    private let hintLabel = UILabel()
    private let shutter = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    // Revisión post-captura: se muestra la foto tomada con "Volver a tomar" /
    // "Usar esta foto" antes de aceptarla, para que el usuario la reemplace si
    // no salió bien.
    private let reviewContainer = UIView()
    private let reviewImageView = UIImageView()
    private var capturedImage: UIImage?
    /// Caja de la credencial (detección en vivo) capturada al disparar, para
    /// recortar la foto a la credencial.
    private var pendingCardBox: CGRect?

    /// Marco guía con forma de tarjeta (ratio ID-1 ≈ 1.585:1), centrado.
    private var guideRect: CGRect = .zero

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        configureSession()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionQueue.async { if !self.session.isRunning { self.session.startRunning() } }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        layoutGuide()
    }

    private func setupUI() {
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        hintLabel.text = "Buscando tu INE…"
        hintLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        hintLabel.textColor = .white.withAlphaComponent(0.85)
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        closeButton.layer.cornerRadius = 20
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "camera.fill")
        cfg.baseForegroundColor = .black
        shutter.configuration = cfg
        shutter.backgroundColor = .white
        shutter.layer.cornerRadius = 36
        shutter.translatesAutoresizingMaskIntoConstraints = false
        shutter.addTarget(self, action: #selector(didTapShutter), for: .touchUpInside)

        [titleLabel, hintLabel, closeButton, shutter].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 64),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -64),

            shutter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            shutter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutter.widthAnchor.constraint(equalToConstant: 72),
            shutter.heightAnchor.constraint(equalToConstant: 72),

            hintLabel.bottomAnchor.constraint(equalTo: shutter.topAnchor, constant: -20),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.55).cgColor
        guideLayer.fillColor = UIColor.clear.cgColor
        guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        guideLayer.lineWidth = 3
        [dimLayer, guideLayer].forEach { view.layer.addSublayer($0) }

        setupReview()
    }

    /// UI de revisión (oculta hasta que hay captura): la foto + "Volver a tomar"
    /// / "Usar esta foto".
    private func setupReview() {
        reviewContainer.backgroundColor = .black
        reviewContainer.isHidden = true
        reviewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reviewContainer)

        let title = UILabel()
        title.text = "¿Se ve bien?"
        title.font = .systemFont(ofSize: 18, weight: .heavy)
        title.textColor = .white
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let sub = UILabel()
        sub.text = "Revisa que se lean todos los datos, sin reflejos ni recortes."
        sub.font = .systemFont(ofSize: 13.5)
        sub.textColor = .white.withAlphaComponent(0.8)
        sub.textAlignment = .center
        sub.numberOfLines = 2
        sub.translatesAutoresizingMaskIntoConstraints = false

        reviewImageView.contentMode = .scaleAspectFit
        reviewImageView.backgroundColor = .black
        reviewImageView.translatesAutoresizingMaskIntoConstraints = false

        let green = UIColor(red: 0.05, green: 0.71, blue: 0.36, alpha: 1)
        let boldTitle: (UIFont) -> UIConfigurationTextAttributesTransformer = { font in
            UIConfigurationTextAttributesTransformer { var c = $0; c.font = font; return c }
        }
        var useCfg = UIButton.Configuration.filled()
        useCfg.baseBackgroundColor = green
        useCfg.baseForegroundColor = .white
        useCfg.title = "Usar esta foto"
        useCfg.cornerStyle = .large
        useCfg.titleTextAttributesTransformer = boldTitle(.systemFont(ofSize: 16, weight: .heavy))
        let use = UIButton(configuration: useCfg)
        use.translatesAutoresizingMaskIntoConstraints = false
        use.addTarget(self, action: #selector(didTapUse), for: .touchUpInside)

        var retakeCfg = UIButton.Configuration.plain()
        retakeCfg.baseForegroundColor = .white
        retakeCfg.title = "Volver a tomar"
        retakeCfg.titleTextAttributesTransformer = boldTitle(.systemFont(ofSize: 14.5, weight: .heavy))
        let retake = UIButton(configuration: retakeCfg)
        retake.translatesAutoresizingMaskIntoConstraints = false
        retake.addTarget(self, action: #selector(didTapRetake), for: .touchUpInside)

        [title, sub, reviewImageView, use, retake].forEach { reviewContainer.addSubview($0) }

        NSLayoutConstraint.activate([
            reviewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            reviewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            reviewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reviewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            title.topAnchor.constraint(equalTo: reviewContainer.safeAreaLayoutGuide.topAnchor, constant: 18),
            title.leadingAnchor.constraint(equalTo: reviewContainer.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: reviewContainer.trailingAnchor, constant: -24),

            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            sub.leadingAnchor.constraint(equalTo: reviewContainer.leadingAnchor, constant: 24),
            sub.trailingAnchor.constraint(equalTo: reviewContainer.trailingAnchor, constant: -24),

            reviewImageView.topAnchor.constraint(equalTo: sub.bottomAnchor, constant: 18),
            reviewImageView.leadingAnchor.constraint(equalTo: reviewContainer.leadingAnchor, constant: 16),
            reviewImageView.trailingAnchor.constraint(equalTo: reviewContainer.trailingAnchor, constant: -16),
            reviewImageView.bottomAnchor.constraint(equalTo: use.topAnchor, constant: -24),

            use.leadingAnchor.constraint(equalTo: reviewContainer.leadingAnchor, constant: 20),
            use.trailingAnchor.constraint(equalTo: reviewContainer.trailingAnchor, constant: -20),
            use.heightAnchor.constraint(equalToConstant: 54),

            retake.topAnchor.constraint(equalTo: use.bottomAnchor, constant: 6),
            retake.centerXAnchor.constraint(equalTo: reviewContainer.centerXAnchor),
            retake.bottomAnchor.constraint(equalTo: reviewContainer.safeAreaLayoutGuide.bottomAnchor, constant: -14),
        ])
    }

    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.showNoCamera() }
                return
            }
            self.session.addInput(input)
            self.configureFocus(device)
            self.processor.device = device

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self.processor, queue: self.videoQueue)
            if self.session.canAddOutput(output) { self.session.addOutput(output) }

            // Forzar portrait: los buffers salen derechos → Vision usa .up y la
            // corrección de perspectiva no necesita reorientar.
            if let conn = output.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if conn.isVideoRotationAngleSupported(90) { conn.videoRotationAngle = 90 }
                } else if conn.isVideoOrientationSupported {
                    conn.videoOrientation = .portrait
                }
            }

            // Salida de FOTO real (full-res, enfoque/exposición fijos) para que la
            // captura final NO sea un frame de video movido/borroso.
            if self.session.canAddOutput(self.photoOutput) {
                self.photoOutput.maxPhotoQualityPrioritization = .quality
                self.session.addOutput(self.photoOutput)
                if let pconn = self.photoOutput.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        if pconn.isVideoRotationAngleSupported(90) { pconn.videoRotationAngle = 90 }
                    } else if pconn.isVideoOrientationSupported {
                        pconn.videoOrientation = .portrait
                    }
                }
            }
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                let layer = AVCaptureVideoPreviewLayer(session: self.session)
                layer.videoGravity = .resizeAspectFill
                layer.frame = self.view.bounds
                self.view.layer.insertSublayer(layer, at: 0)
                self.previewLayer = layer
                self.layoutGuide()
                self.bindCallbacks()
            }
        }
    }

    private func bindCallbacks() {
        processor.onResult = { [weak self] result in self?.apply(result) }
        // El detector solo SEÑALA que está listo; la imagen final viene de una
        // foto real (nítida), no del frame de video que recortaba el procesador.
        processor.onAutoCapture = { [weak self] _ in self?.triggerPhoto() }
    }

    /// Afina el enfoque para una credencial cerca de la cámara: autofoco continuo
    /// + suave, restricción a rango cercano y exposición continua. Reduce las
    /// capturas borrosas (la INE suele estar a < 20 cm).
    private func configureFocus(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = true
            }
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            print("[INEScanner] focus config failed:", error)
        }
    }

    /// Recalcula el marco guía (tarjeta centrada) y la guía normalizada que usa
    /// el procesador para validar alineación.
    private func layoutGuide() {
        let w = view.bounds.width
        let cardW = min(w - 48, 460)
        let cardH = cardW / 1.585
        let rect = CGRect(
            x: (view.bounds.width - cardW) / 2,
            y: (view.bounds.height - cardH) / 2 - 20,
            width: cardW, height: cardH
        )
        guideRect = rect

        let path = UIBezierPath(rect: view.bounds)
        let hole = UIBezierPath(roundedRect: rect, cornerRadius: 18)
        path.append(hole)
        dimLayer.path = path.cgPath

        guideLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: 18).cgPath

        // Guía en coords normalizadas Vision (origen abajo-izquierda).
        let h = view.bounds.height
        processor.guideNormalized = CGRect(
            x: rect.minX / w,
            y: 1 - rect.maxY / h,
            width: rect.width / w,
            height: rect.height / h
        )
    }

    private func apply(_ result: FrameResult) {
        let green = UIColor(red: 0.05, green: 0.71, blue: 0.36, alpha: 1) // TreggaColors.primary
        if result.aligned && result.focused {
            // Verde = bien encuadrada y nítida → toca el botón para capturar.
            guideLayer.strokeColor = green.cgColor
            guideLayer.lineWidth = 4
            hintLabel.text = "¡Listo! Toca el botón para capturar"
            hintLabel.textColor = green
        } else if result.aligned {
            // Bien encuadrada pero la cámara aún enfoca → NO capturamos (evita borrosa).
            guideLayer.strokeColor = UIColor.systemYellow.cgColor
            guideLayer.lineWidth = 4
            hintLabel.text = "Enfocando… mantén firme"
            hintLabel.textColor = .systemYellow
        } else {
            guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
            guideLayer.lineWidth = 3
            hintLabel.text = result.box == nil ? "Buscando tu INE…" : "Acerca y centra la credencial"
            hintLabel.textColor = .white.withAlphaComponent(0.85)
        }
    }

    /// Tras capturar (auto o manual) NO se acepta de una: se pausa la cámara y se
    /// muestra la revisión para que el usuario confirme o vuelva a tomar.
    private func finish(with image: UIImage) {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
        capturedImage = image
        reviewImageView.image = image
        reviewContainer.isHidden = false
        view.bringSubviewToFront(reviewContainer)
    }

    @objc private func didTapUse() {
        guard let image = capturedImage else { return }
        onCapture?(image)
    }

    @objc private func didTapRetake() {
        capturedImage = nil
        reviewContainer.isHidden = true
        processor.reset()
        sessionQueue.async { if !self.session.isRunning { self.session.startRunning() } }
    }

    // MARK: - Foto real (nítida)

    private func triggerPhoto() {
        // Caja del documento de la detección en vivo (ya validada) para recortar.
        pendingCardBox = processor.lastBox
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    public func photoOutput(_ output: AVCapturePhotoOutput,
                            didFinishProcessingPhoto photo: AVCapturePhoto,
                            error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let raw = UIImage(data: data) else {
            // La foto falló: reinicia para permitir reintentar.
            DispatchQueue.main.async {
                self.processor.reset()
                self.sessionQueue.async { if !self.session.isRunning { self.session.startRunning() } }
            }
            return
        }
        let up = upright(raw)
        let cropped = cropToCard(up) ?? up
        DispatchQueue.main.async { self.finish(with: cropped) }
    }

    /// Normaliza la orientación de la foto a `.up` (la cámara entrega EXIF; la
    /// redibujamos derecha para detectar y recortar bien).
    private func upright(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
    }

    /// Detecta la credencial en la foto nítida y recorta a su CAJA delimitadora
    /// (axis-aligned) con margen. El mapeo Vision→píxeles (origen abajo-izq → píxel)
    /// es estándar y confiable; un recorte rectangular no inclina ni estira.
    /// Devuelve nil si no detecta (se usa la foto completa).
    private func cropToCard(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        // 1) Caja de la detección EN VIVO (la que disparó la captura). El buffer de
        //    video y la foto comparten encuadre/orientación, así que se traslada.
        // 2) Si no hay, re-detecta sobre la foto. 3) Si no, foto completa (fallback).
        var bb = pendingCardBox
        if bb == nil {
            let request = VNDetectDocumentSegmentationRequest()
            try? VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:]).perform([request])
            if let obs = request.results?.first, obs.confidence >= 0.4 { bb = obs.boundingBox }
        }
        guard let bb else { return nil }
        let W = CGFloat(cg.width), H = CGFloat(cg.height)
        let padX = bb.width * 0.05, padY = bb.height * 0.08
        var rect = CGRect(
            x: (bb.minX - padX) * W,
            y: (1 - bb.maxY - padY) * H,           // flip Y → origen arriba-izquierda
            width: (bb.width + padX * 2) * W,
            height: (bb.height + padY * 2) * H
        )
        rect = rect.integral.intersection(CGRect(x: 0, y: 0, width: W, height: H))
        guard rect.width > 80, rect.height > 80, let out = cg.cropping(to: rect) else { return nil }
        return UIImage(cgImage: out)
    }

    private func showNoCamera() {
        hintLabel.text = "La cámara no está disponible en este dispositivo."
        shutter.isHidden = true
    }

    @objc private func didTapShutter() {
        // Disparo manual: si el procesador permite capturar, tomamos la foto real.
        if processor.beginCapture() { triggerPhoto() }
    }

    @objc private func didTapClose() {
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
        onCancel?()
    }
}
