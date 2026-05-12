import UIKit

final class TextReaderViewController: UIViewController {
    private let item: ReaderItem
    private let url: URL
    private let textView = UITextView()

    init(item: ReaderItem, url: URL) {
        self.item = item
        self.url = url
        super.init(nibName: nil, bundle: nil)
        title = item.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(share)),
            UIBarButtonItem(title: "Aa", style: .plain, target: self, action: #selector(toggleFont))
        ]

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = UIEdgeInsets(top: 24, left: 18, bottom: 40, right: 18)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadText()
    }

    private func loadText() {
        do {
            let data = try Data(contentsOf: url)
            let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) ?? String(data: data, encoding: .ascii) ?? "无法以文本方式读取该文件。"
            textView.text = text
        } catch {
            textView.text = "读取失败：\(error.localizedDescription)"
        }
    }

    @objc private func toggleFont() {
        let isMono = textView.font?.fontName.lowercased().contains("mono") ?? false
        textView.font = isMono ? .preferredFont(forTextStyle: .body) : .monospacedSystemFont(ofSize: 15, weight: .regular)
    }

    @objc private func share() {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        present(controller, animated: true)
    }
}

final class ImageReaderViewController: UIViewController, UIScrollViewDelegate {
    private let item: ReaderItem
    private let url: URL
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    init(item: ReaderItem, url: URL) {
        self.item = item
        self.url = url
        super.init(nibName: nil, bundle: nil)
        title = item.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(share))

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.backgroundColor = .black
        view.addSubview(scrollView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(contentsOfFile: url.path)
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    @objc private func share() {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        present(controller, animated: true)
    }
}
