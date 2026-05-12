import UIKit
import PhotosUI
import Vision

final class OCRToolsViewController: UIViewController, PHPickerViewControllerDelegate {
    private let imageView = UIImageView()
    private let resultView = UITextView()
    private let pickButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private var recognizedText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "OCR 识别"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        setupViews()
    }

    private func setupViews() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 18
        scrollView.addSubview(stack)

        let imageCard = UIView()
        imageCard.backgroundColor = EggDesign.cardBackground()
        imageCard.layer.cornerRadius = 24
        imageCard.layer.cornerCurve = .continuous
        EggDesign.applyCardShadow(to: imageCard)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "photo.on.rectangle.angled")
        imageView.tintColor = .tertiaryLabel
        imageView.backgroundColor = .systemBackground
        imageView.layer.cornerRadius = 18
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        imageCard.addSubview(imageView)

        configurePrimary(pickButton, title: "选择图片并识别", icon: "text.viewfinder")
        pickButton.addTarget(self, action: #selector(pickImage), for: .touchUpInside)

        let resultCard = UIView()
        resultCard.backgroundColor = EggDesign.cardBackground()
        resultCard.layer.cornerRadius = 24
        resultCard.layer.cornerCurve = .continuous
        EggDesign.applyCardShadow(to: resultCard)

        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.text = "识别结果会显示在这里。"
        resultView.textColor = .secondaryLabel
        resultView.font = .preferredFont(forTextStyle: .body)
        resultView.backgroundColor = .clear
        resultView.isEditable = false
        resultView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        resultCard.addSubview(resultView)

        let buttonRow = UIStackView(arrangedSubviews: [copyButton, shareButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 12
        buttonRow.distribution = .fillEqually

        configureSecondary(copyButton, title: "复制文本", icon: "doc.on.doc")
        copyButton.addTarget(self, action: #selector(copyText), for: .touchUpInside)
        configureSecondary(shareButton, title: "分享", icon: "square.and.arrow.up")
        shareButton.addTarget(self, action: #selector(shareText), for: .touchUpInside)

        stack.addArrangedSubview(imageCard)
        stack.addArrangedSubview(pickButton)
        stack.addArrangedSubview(resultCard)
        stack.addArrangedSubview(buttonRow)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),

            imageCard.heightAnchor.constraint(equalToConstant: 260),
            imageView.leadingAnchor.constraint(equalTo: imageCard.leadingAnchor, constant: 14),
            imageView.trailingAnchor.constraint(equalTo: imageCard.trailingAnchor, constant: -14),
            imageView.topAnchor.constraint(equalTo: imageCard.topAnchor, constant: 14),
            imageView.bottomAnchor.constraint(equalTo: imageCard.bottomAnchor, constant: -14),

            pickButton.heightAnchor.constraint(equalToConstant: 52),
            resultCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),
            resultView.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor),
            resultView.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor),
            resultView.topAnchor.constraint(equalTo: resultCard.topAnchor),
            resultView.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor),
            buttonRow.heightAnchor.constraint(equalToConstant: 48)
        ])
        updateActionButtons()
    }

    private func configurePrimary(_ button: UIButton, title: String, icon: String) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 8
        config.cornerStyle = .large
        config.baseBackgroundColor = AppSettings.shared.accentStyle.tintColor
        config.baseForegroundColor = .white
        button.configuration = config
    }

    private func configureSecondary(_ button: UIButton, title: String, icon: String) {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 8
        config.cornerStyle = .large
        config.baseForegroundColor = AppSettings.shared.accentStyle.tintColor
        button.configuration = config
    }

    @objc private func pickImage() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            showAlert(title: "无法读取", message: "请选择有效图片。")
            return
        }
        resultView.text = "正在识别..."
        resultView.textColor = .secondaryLabel
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self = self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
                self.imageView.tintColor = nil
            }
            self.recognize(image)
        }
    }

    private func recognize(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { self.showAlert(title: "识别失败", message: "无法读取图片数据。") }
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error {
                DispatchQueue.main.async { self.showAlert(title: "识别失败", message: error.localizedDescription) }
                return
            }
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let text = lines.joined(separator: "\n")
            DispatchQueue.main.async {
                self.recognizedText = text
                self.resultView.text = text.isEmpty ? "没有识别到文字。" : text
                self.resultView.textColor = text.isEmpty ? .secondaryLabel : .label
                self.updateActionButtons()
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { self.showAlert(title: "识别失败", message: error.localizedDescription) }
            }
        }
    }

    @objc private func copyText() {
        guard !recognizedText.isEmpty else { return }
        UIPasteboard.general.string = recognizedText
        showAlert(title: "已复制", message: "识别文本已经复制到剪贴板。")
    }

    @objc private func shareText() {
        guard !recognizedText.isEmpty else { return }
        let controller = UIActivityViewController(activityItems: [recognizedText], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        present(controller, animated: true)
    }

    private func updateActionButtons() {
        let enabled = !recognizedText.isEmpty
        copyButton.isEnabled = enabled
        shareButton.isEnabled = enabled
        copyButton.alpha = enabled ? 1.0 : 0.45
        shareButton.alpha = enabled ? 1.0 : 0.45
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
