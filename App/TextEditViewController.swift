import UIKit

final class TextEditViewController: UIViewController, UITextViewDelegate {
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let initialText: String
    private let placeholder: String
    private let onSave: (String) -> Void

    init(titleText: String, value: String, placeholder: String, onSave: @escaping (String) -> Void) {
        self.initialText = value
        self.placeholder = placeholder
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        title = titleText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveAction))

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 16
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.text = initialText
        textView.delegate = self
        view.addSubview(textView)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.font = .preferredFont(forTextStyle: .body)
        placeholderLabel.isHidden = !initialText.isEmpty
        view.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 180),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 18),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -18)
        ])
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    @objc private func saveAction() {
        onSave(textView.text.trimmingCharacters(in: .whitespacesAndNewlines))
        navigationController?.popViewController(animated: true)
    }
}
