import UIKit

final class TextToolsViewController: UITableViewController {
    private enum Tool: Int, CaseIterable {
        case wordCount
        case urlEncode
        case urlDecode
        case base64Encode
        case base64Decode
        case jsonPretty
        case uuid
        case timestamp

        var title: String {
            switch self {
            case .wordCount: return "字数统计"
            case .urlEncode: return "URL 编码"
            case .urlDecode: return "URL 解码"
            case .base64Encode: return "Base64 编码"
            case .base64Decode: return "Base64 解码"
            case .jsonPretty: return "JSON 格式化"
            case .uuid: return "UUID 生成"
            case .timestamp: return "时间戳转换"
            }
        }

        var subtitle: String {
            switch self {
            case .wordCount: return "统计字符、单词、行数"
            case .urlEncode: return "把文本转换为 URL 安全字符串"
            case .urlDecode: return "还原百分号编码字符串"
            case .base64Encode: return "UTF-8 文本转 Base64"
            case .base64Decode: return "Base64 还原为 UTF-8 文本"
            case .jsonPretty: return "格式化并校验 JSON"
            case .uuid: return "生成新的 UUID"
            case .timestamp: return "当前时间戳与日期互转"
            }
        }

        var icon: String {
            switch self {
            case .wordCount: return "textformat.size"
            case .urlEncode, .urlDecode: return "link"
            case .base64Encode, .base64Decode: return "number"
            case .jsonPretty: return "curlybraces"
            case .uuid: return "number.square"
            case .timestamp: return "clock"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文本工具"
        navigationItem.largeTitleDisplayMode = .always
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Tool.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "这些工具全部在本地运行，不上传你的文本内容。"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let tool = Tool.allCases[indexPath.row]
        var content = UIListContentConfiguration.subtitleCell()
        content.text = tool.title
        content.secondaryText = tool.subtitle
        content.image = UIImage(systemName: tool.icon)
        content.imageProperties.tintColor = AppSettings.shared.accentStyle.tintColor
        cell.contentConfiguration = content
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tool = Tool.allCases[indexPath.row]
        switch tool {
        case .uuid:
            showGenerated(title: "UUID", result: UUID().uuidString)
        case .timestamp:
            showTimestampTool()
        default:
            pushInputTool(tool)
        }
    }

    private func pushInputTool(_ tool: Tool) {
        let controller = TextToolInputViewController(titleText: tool.title, placeholder: placeholder(for: tool)) { [weak self] input in
            self?.process(tool: tool, input: input)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func placeholder(for tool: Tool) -> String {
        switch tool {
        case .wordCount: return "输入要统计的文本"
        case .urlEncode: return "输入要 URL 编码的文本"
        case .urlDecode: return "输入要 URL 解码的文本"
        case .base64Encode: return "输入要 Base64 编码的文本"
        case .base64Decode: return "输入 Base64 字符串"
        case .jsonPretty: return "粘贴 JSON 文本"
        case .uuid: return ""
        case .timestamp: return ""
        }
    }

    private func process(tool: Tool, input: String) {
        let result: String
        switch tool {
        case .wordCount:
            let characters = input.count
            let words = input.split { $0.isWhitespace || $0.isNewline }.count
            let lines = input.components(separatedBy: .newlines).count
            result = "字符数：\(characters)\n词数：\(words)\n行数：\(lines)"
        case .urlEncode:
            result = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "编码失败"
        case .urlDecode:
            result = input.removingPercentEncoding ?? "解码失败"
        case .base64Encode:
            result = Data(input.utf8).base64EncodedString()
        case .base64Decode:
            if let data = Data(base64Encoded: input.trimmingCharacters(in: .whitespacesAndNewlines)), let text = String(data: data, encoding: .utf8) {
                result = text
            } else {
                result = "Base64 解码失败：请检查输入是否为有效 UTF-8 文本。"
            }
        case .jsonPretty:
            if let data = input.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data), let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]), let text = String(data: pretty, encoding: .utf8) {
                result = text
            } else {
                result = "JSON 格式化失败：请检查 JSON 语法。"
            }
        case .uuid, .timestamp:
            result = ""
        }
        showGenerated(title: tool.title, result: result)
    }

    private func showTimestampTool() {
        let now = Date()
        let seconds = Int(now.timeIntervalSince1970)
        let milliseconds = Int(now.timeIntervalSince1970 * 1000)
        let formatter = ISO8601DateFormatter()
        let result = "当前时间：\(formatter.string(from: now))\nUnix 秒：\(seconds)\nUnix 毫秒：\(milliseconds)"
        showGenerated(title: "时间戳", result: result)
    }

    private func showGenerated(title: String, result: String) {
        let controller = TextToolResultViewController(titleText: title, result: result)
        navigationController?.pushViewController(controller, animated: true)
    }
}

final class TextToolInputViewController: UIViewController, UITextViewDelegate {
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let placeholder: String
    private let onRun: (String) -> Void

    init(titleText: String, placeholder: String, onRun: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.onRun = onRun
        super.init(nibName: nil, bundle: nil)
        title = titleText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "运行", style: .done, target: self, action: #selector(run))

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 18
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        textView.delegate = self
        view.addSubview(textView)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.font = .preferredFont(forTextStyle: .body)
        view.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 260),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 18),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -18)
        ])
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    @objc private func run() {
        onRun(textView.text)
    }
}

final class TextToolResultViewController: UIViewController {
    private let result: String
    private let textView = UITextView()

    init(titleText: String, result: String) {
        self.result = result
        super.init(nibName: nil, bundle: nil)
        title = titleText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "复制", style: .done, target: self, action: #selector(copyResult))
        ]

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.text = result
        textView.isEditable = false
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 18
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    @objc private func copyResult() {
        UIPasteboard.general.string = result
        let alert = UIAlertController(title: "已复制", message: "结果已经复制到剪贴板。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
