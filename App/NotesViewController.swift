import UIKit

final class NotesViewController: UITableViewController, UISearchResultsUpdating {
    private let store = NoteStore.shared
    private let searchController = UISearchController(searchResultsController: nil)
    private var keyword = ""

    private var visibleNotes: [NoteItem] {
        store.filtered(keyword: keyword)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "记录"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(EggCardCell.self, forCellReuseIdentifier: EggCardCell.reuseIdentifier)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索笔记"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        keyword = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(visibleNotes.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "笔记保存在本机 UserDefaults 中。后续可迁移到 SQLite / SwiftData，并加入 Markdown、标签和附件。"
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        visibleNotes.isEmpty ? UITableView.automaticDimension : 92
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .none
        cell.accessoryView = nil

        guard !visibleNotes.isEmpty else {
            var content = UIListContentConfiguration.subtitleCell()
            content.text = keyword.isEmpty ? "还没有笔记" : "没有匹配的笔记"
            content.secondaryText = keyword.isEmpty ? "点击右上角 + 记录一个想法" : "换个关键词试试"
            content.image = UIImage(systemName: "note.text")
            content.imageProperties.tintColor = AppSettings.shared.accentStyle.tintColor
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            return cell
        }

        let note = visibleNotes[indexPath.row]
        let card = tableView.dequeueReusableCell(withIdentifier: EggCardCell.reuseIdentifier, for: indexPath) as! EggCardCell
        card.configure(
            title: note.title,
            subtitle: subtitle(for: note),
            icon: note.isPinned ? "pin.fill" : "note.text",
            tint: note.isPinned ? .systemOrange : AppSettings.shared.accentStyle.tintColor,
            trailing: note.isPinned ? "置顶" : nil,
            showsChevron: true
        )
        return card
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !visibleNotes.isEmpty else { return }
        let note = visibleNotes[indexPath.row]
        openEditor(note: note)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !visibleNotes.isEmpty else { return nil }
        let note = visibleNotes[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            self?.store.delete(note)
            self?.tableView.reloadData()
            done(true)
        }

        let pin = UIContextualAction(style: .normal, title: note.isPinned ? "取消置顶" : "置顶") { [weak self] _, _, done in
            self?.store.togglePinned(note)
            self?.tableView.reloadData()
            done(true)
        }
        pin.backgroundColor = .systemOrange

        return UISwipeActionsConfiguration(actions: [delete, pin])
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !visibleNotes.isEmpty else { return nil }
        let note = visibleNotes[indexPath.row]

        let copy = UIContextualAction(style: .normal, title: "复制") { _, _, done in
            UIPasteboard.general.string = "\(note.title)\n\n\(note.body)"
            done(true)
        }
        copy.backgroundColor = .systemBlue

        let share = UIContextualAction(style: .normal, title: "分享") { [weak self] _, _, done in
            let text = "\(note.title)\n\n\(note.body)"
            let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            controller.popoverPresentationController?.sourceView = self?.tableView
            self?.present(controller, animated: true)
            done(true)
        }
        share.backgroundColor = .systemGreen

        return UISwipeActionsConfiguration(actions: [copy, share])
    }

    private func subtitle(for note: NoteItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let preview = note.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let dateText = "更新：\(formatter.string(from: note.updatedAt))"
        if preview.isEmpty { return dateText }
        return "\(dateText) · \(preview)"
    }

    @objc private func addNote() {
        openEditor(note: nil)
    }

    private func openEditor(note: NoteItem?) {
        let controller = NoteEditorViewController(note: note) { [weak self] title, body in
            guard let self = self else { return }
            if let note {
                self.store.update(note, title: title, body: body)
            } else {
                self.store.add(title: title, body: body)
            }
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}

final class NoteEditorViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    private let titleField = UITextField()
    private let bodyView = UITextView()
    private let placeholderLabel = UILabel()
    private let note: NoteItem?
    private let onSave: (String, String) -> Void

    init(note: NoteItem?, onSave: @escaping (String, String) -> Void) {
        self.note = note
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        title = note == nil ? "新建笔记" : "编辑笔记"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.placeholder = "标题"
        titleField.text = note?.title
        titleField.font = .preferredFont(forTextStyle: .title2)
        titleField.backgroundColor = .secondarySystemGroupedBackground
        titleField.layer.cornerRadius = 16
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        titleField.leftViewMode = .always
        titleField.returnKeyType = .next
        titleField.delegate = self
        view.addSubview(titleField)

        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.text = note?.body
        bodyView.font = .preferredFont(forTextStyle: .body)
        bodyView.backgroundColor = .secondarySystemGroupedBackground
        bodyView.layer.cornerRadius = 16
        bodyView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        bodyView.delegate = self
        view.addSubview(bodyView)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "记录想法、资料、灵感或临时信息"
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.font = .preferredFont(forTextStyle: .body)
        placeholderLabel.isHidden = !(note?.body ?? "").isEmpty
        view.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            titleField.heightAnchor.constraint(equalToConstant: 54),

            bodyView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 14),
            bodyView.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            bodyView.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            bodyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            placeholderLabel.topAnchor.constraint(equalTo: bodyView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor, constant: 18),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: bodyView.trailingAnchor, constant: -18)
        ])
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        bodyView.becomeFirstResponder()
        return true
    }

    @objc private func save() {
        let body = bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawTitle = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let title = rawTitle.isEmpty ? autoTitle(from: body) : rawTitle

        guard !title.isEmpty || !body.isEmpty else {
            let alert = UIAlertController(title: "空笔记", message: "请先输入标题或正文。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default))
            present(alert, animated: true)
            return
        }

        onSave(title.isEmpty ? "未命名笔记" : title, body)
        navigationController?.popViewController(animated: true)
    }

    private func autoTitle(from body: String) -> String {
        let firstLine = body.components(separatedBy: .newlines).first ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return String(trimmed.prefix(24))
    }
}
