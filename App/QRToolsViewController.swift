import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class QRToolsViewController: UIViewController, UITextViewDelegate {
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let imageView = UIImageView()
    private let generateButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private var generatedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "二维码"
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

        let inputCard = UIView()
        inputCard.backgroundColor = EggDesign.cardBackground()
        inputCard.layer.cornerRadius = 22
        inputCard.layer.cornerCurve = .continuous
        EggDesign.applyCardShadow(to: inputCard)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        textView.delegate = self
        inputCard.addSubview(textView)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "输入要生成二维码的文本或链接"
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.font = .preferredFont(forTextStyle: .body)
        inputCard.addSubview(placeholderLabel)

        let previewCard = UIView()
        previewCard.backgroundColor = EggDesign.cardBackground()
        previewCard.layer.cornerRadius = 28
        previewCard.layer.cornerCurve = .continuous
        EggDesign.applyCardShadow(to: previewCard)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "qrcode")
        imageView.tintColor = .tertiaryLabel
        imageView.backgroundColor = .systemBackground
        imageView.layer.cornerRadius = 22
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        previewCard.addSubview(imageView)

        configurePrimary(generateButton, title: "生成二维码", icon: "qrcode")
        generateButton.addTarget(self, action: #selector(generate), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [copyButton, shareButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 12
        buttonRow.distribution = .fillEqually

        configureSecondary(copyButton, title: "复制图片", icon: "doc.on.doc")
        copyButton.addTarget(self, action: #selector(copyImage), for: .touchUpInside)
        configureSecondary(shareButton, title: "分享", icon: "square.and.arrow.up")
        shareButton.addTarget(self, action: #selector(shareImage), for: .touchUpInside)

        stack.addArrangedSubview(inputCard)
        stack.addArrangedSubview(generateButton)
        stack.addArrangedSubview(previewCard)
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

            inputCard.heightAnchor.constraint(equalToConstant: 150),
            textView.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor),
            textView.topAnchor.constraint(equalTo: inputCard.topAnchor),
            textView.bottomAnchor.constraint(equalTo: inputCard.bottomAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: inputCard.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: 20),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: inputCard.trailingAnchor, constant: -20),

            generateButton.heightAnchor.constraint(equalToConstant: 52),
            previewCard.heightAnchor.constraint(equalToConstant: 320),
            imageView.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: previewCard.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 260),
            imageView.heightAnchor.constraint(equalToConstant: 260),
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

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    @objc private func generate() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showAlert(title: "请输入内容", message: "二维码需要一段文本或链接。")
            return
        }
        guard let image = makeQRCode(from: text) else {
            showAlert(title: "生成失败", message: "无法生成二维码，请换一段内容试试。")
            return
        }
        generatedImage = image
        imageView.image = image
        imageView.tintColor = nil
        updateActionButtons()
    }

    private func makeQRCode(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 12, y: 12)
        let scaled = output.transformed(by: transform)
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    @objc private func copyImage() {
        guard let image = generatedImage else { return }
        UIPasteboard.general.image = image
        showAlert(title: "已复制", message: "二维码图片已经复制到剪贴板。")
    }

    @objc private func shareImage() {
        guard let image = generatedImage else { return }
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        present(controller, animated: true)
    }

    private func updateActionButtons() {
        let enabled = generatedImage != nil
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
