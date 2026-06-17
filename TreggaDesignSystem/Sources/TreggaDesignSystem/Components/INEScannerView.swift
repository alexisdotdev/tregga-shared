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
}

/// Procesa frames fuera del main thread y devuelve callbacks ya en main.
private final class RectProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    /// Rect guía en coordenadas normalizadas (origen abajo-izquierda) contra el
    /// que se valida la alineación. Lo fija el controller según el tamaño real.
    var guideNormalized: CGRect = CGRect(x: 0.08, y: 0.34, width: 0.84, height: 0.32)
    var onResult: ((FrameResult) -> Void)?
    var onAutoCapture: ((UIImage) -> Void)?

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

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.5   // tarjeta ID-1 ≈ 0.63 (corto/largo)
        request.maximumAspectRatio = 0.8
        request.minimumSize = 0.3
        request.quadratureTolerance = 28

        // El connection se fuerza a portrait → la imagen ya viene derecha (.up).
        let handler = VNImageRequestHandler(cvPixelBuffer: pb, orientation: .up, options: [:])
        try? handler.perform([request])
        let obs = (request.results)?.first
        latestObs = obs

        let aligned = obs.map { isAligned($0.boundingBox) } ?? false
        if aligned { alignedStreak += 1 } else { alignedStreak = max(0, alignedStreak - 1) }

        if !didCapture, aligned, alignedStreak >= 8, let obs {
            didCapture = true
            let image = crop(pb, obs)
            DispatchQueue.main.async { self.onAutoCapture?(image) }
            return
        }

        let result = FrameResult(box: obs?.boundingBox, aligned: aligned)
        DispatchQueue.main.async { self.onResult?(result) }
    }

    /// Captura manual (botón de disparo): usa el último frame; recorta si hay
    /// rectángulo detectado, si no devuelve el frame completo.
    func captureManually(completion: @escaping (UIImage) -> Void) {
        guard !didCapture, let pb = latestBuffer else { return }
        didCapture = true
        let image: UIImage
        if let obs = latestObs { image = crop(pb, obs) }
        else { image = fullFrame(pb) }
        DispatchQueue.main.async { completion(image) }
    }

    /// Alineado = el rectángulo detectado cubre bien la guía y no se sale.
    private func isAligned(_ box: CGRect) -> Bool {
        let g = guideNormalized
        let coversWidth = box.width >= g.width * 0.78
        let centeredX = abs(box.midX - g.midX) <= 0.08
        let centeredY = abs(box.midY - g.midY) <= 0.10
        let inside = box.minX >= g.minX - 0.10 && box.maxX <= g.maxX + 0.10
            && box.minY >= g.minY - 0.12 && box.maxY <= g.maxY + 0.12
        return coversWidth && centeredX && centeredY && inside
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

public final class INEScannerController: UIViewController {
    var titleText: String = ""
    var onCapture: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let processor = RectProcessor()
    private let sessionQueue = DispatchQueue(label: "app.tregga.ine-scanner.session")
    private let videoQueue = DispatchQueue(label: "app.tregga.ine-scanner.video")
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let dimLayer = CAShapeLayer()
    private let guideLayer = CAShapeLayer()
    private let detectLayer = CAShapeLayer()
    private let titleLabel = UILabel()
    private let hintLabel = UILabel()
    private let shutter = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

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
        detectLayer.fillColor = UIColor.clear.cgColor
        detectLayer.strokeColor = UIColor.clear.cgColor
        detectLayer.lineWidth = 3
        [dimLayer, guideLayer, detectLayer].forEach { view.layer.addSublayer($0) }
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
        processor.onAutoCapture = { [weak self] image in self?.finish(with: image) }
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
        if result.aligned {
            guideLayer.strokeColor = green.cgColor
            guideLayer.lineWidth = 4
            hintLabel.text = "¡Listo! Mantén firme el celular…"
            hintLabel.textColor = green
        } else {
            guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
            guideLayer.lineWidth = 3
            hintLabel.text = result.box == nil ? "Buscando tu INE…" : "Acerca y centra la credencial"
            hintLabel.textColor = .white.withAlphaComponent(0.85)
        }

        // Dibuja el rectángulo detectado mapeado a la vista.
        guard let box = result.box, let preview = previewLayer else {
            detectLayer.strokeColor = UIColor.clear.cgColor
            return
        }
        let meta = CGRect(x: box.minX, y: 1 - box.maxY, width: box.width, height: box.height)
        let viewRect = preview.layerRectConverted(fromMetadataOutputRect: meta)
        detectLayer.path = UIBezierPath(roundedRect: viewRect, cornerRadius: 12).cgPath
        detectLayer.strokeColor = (result.aligned ? green : UIColor.white.withAlphaComponent(0.5)).cgColor
    }

    private func finish(with image: UIImage) {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
        onCapture?(image)
    }

    private func showNoCamera() {
        hintLabel.text = "La cámara no está disponible en este dispositivo."
        shutter.isHidden = true
    }

    @objc private func didTapShutter() {
        processor.captureManually { [weak self] image in self?.finish(with: image) }
    }

    @objc private func didTapClose() {
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
        onCancel?()
    }
}
