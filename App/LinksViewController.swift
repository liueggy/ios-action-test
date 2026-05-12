import UIKit

final class LinksViewController: UITableViewController, UISearchResultsUpdating {
    private let store = LinkStore.shared
    private let searchController = UISearchController(searchResultsController: nil)
    private var keyword = ""

    private var visibleLinks: [LinkItem] { store.filtered(keyword: keyword) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "链接收藏"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLink))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(EggCardCell.self, forCellReuseIdentifier: EggCardCell.reuseIdentifier)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索标题、网址或备注"
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
        max(visibleLinks.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "用于保存网页、资料、文档和灵感链接。后续可接入 LinkPresentation 生成网页预览。"
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        visibleLinks.isEmpty ? UITableView.automaticDimension : 92
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .none

        guard !visibleLinks.isEmpty else {
            var content = UIListContentConfiguration.subtitleCell()
            content.text = keyword.isEmpty ? "还没有收藏链接" : "没有匹配的链接"
            content.secondaryText = keyword.isEmpty ? "点击右上角 + 保存一个网页或资料链接" : "换个关键词试试"
            content.image = UIImage(systemName: "link.circle")
            content.imageProperties.tintColor = AppSettings.shared.accentStyle.tintColor
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            return cell
        }

        let link = visibleLinks[indexPath.row]
        let card = tableView.dequeueReusableCell(withIdentifier: EggCardCell.reuseIdentifier, for: indexPath) as! EggCardCell
        card.configure(
            title: link.title,
            subtitle: subtitle(for: link),
            icon: link.isPinned ? "pin.fill" : "link.circle.fill",
            tint: link.isPinned ? .systemOrange : AppSettings.shared.accentStyle.tintColor,
            trailing: link.isPinned ? "置顶" : nil,
            showsChevron: true
        )
        return card
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !visibleLinks.isEmpty else { return }
        let link = visibleLinks[indexPath.row]
        openActions(for: link)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !visibleLinks.isEmpty else { return nil }
        let link = visibleLinks[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            self?.store.delete(link)
            self?.tableView.reloadData()
            done(true)
        }
        let pin = UIContextualAction(style: .normal, title: link.isPinned ? "取消置顶" : "置顶") { [weak self] _, _, done in
            self?.store.togglePinned(link)
            self?.tableView.reloadData()
            done(true)
        }
        pin.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [delete, pin])
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !visibleLinks.isEmpty else { return nil }
        let link = visibleLinks[indexPath.row]

        let open = UIContextualAction(style: .normal, title: "打开") { [weak self] _, _, done in
            self?.open(link)
            done(true)
        }
        open.backgroundColor = .systemGreen

        let copy = UIContextualAction(style: .normal, title: "复制") { _, _, done in
            UIPasteboard.general.string = link.urlString
            done(true)
        }
        copy.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [open, copy])
    }

    private func subtitle(for link: LinkItem) -> String {
        let note = link.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if note.isEmpty { return link.urlString }
        return "\(link.urlString) · \(note)"
    }

    private func openActions(for link: LinkItem) {
        let alert = UIAlertController(title: link.title, message: link.urlString, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "打开链接", style: .default) { [weak self] _ in self?.open(link) })
        alert.addAction(UIAlertAction(title: "编辑", style: .default) { [weak self] _ in self?.openEditor(link: link) })
        alert.addAction(UIAlertAction(title: "复制链接", style: .default) { _ in UIPasteboard.general.string = link.urlString })
        alert.addAction(UIAlertAction(title: "分享", style: .default) { [weak self] _ in self?.share(link) })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.sourceView = tableView
        present(alert, animated: true)
    }

    private func open(_ link: LinkItem) {
        guard let url = link.normalizedURL else { showError("链接格式无效。") ; return }
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            if !success { DispatchQueue.main.async { self?.showError("无法打开该链接。") } }
        }
    }

    private func share(_ link: LinkItem) {
        let text = "\(link.title)\n\(link.urlString)\n\n\(link.notes)"
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = tableView
        present(controller, animated: true)
    }

    @objc private func addLink() { openEditor(link: nil) }

    private func openEditor(link: LinkItem?) {
        let controller = LinkEditorViewController(link: link) { [weak self] title, urlString, notes in
            guard let self = self else { return }
            if let link {
                self.store.update(link, title: title, urlString: urlString, notes: notes)
            } else {
                self.store.add(title: title, urlString: urlString, notes: notes)
            }
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "操作失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}

final class LinkEditorViewController: UITableViewController {
    private let titleField = UITextField()
    private let urlField = UITextField()
    private let notesView = UITextView()
    private let link: LinkItem?
    private let onSave: (String, String, String) -> Void

    init(link: LinkItem?, onSave: @escaping (String, String, String) -> Void) {
        self.link = link
        self.onSave = onSave
        super.init(style: .insetGrouped)
        title = link == nil ? "新增链接" : "编辑链接"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        tableView.backgroundColor = .systemGroupedBackground

        titleField.placeholder = "标题"
        titleField.text = link?.title
        titleField.clearButtonMode = .whileEditing

        urlField.placeholder = "https://example.com"
        urlField.text = link?.urlString
        urlField.keyboardType = .URL
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.clearButtonMode = .whileEditing

        notesView.text = link?.notes
        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.backgroundColor = .clear
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 2 : 1 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { section == 0 ? "链接信息" : "备注" }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { indexPath.section == 1 ? 160 : 52 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.selectionStyle = .none
        if indexPath.section == 0 && indexPath.row == 0 {
            embed(titleField, in: cell)
        } else if indexPath.section == 0 {
            embed(urlField, in: cell)
        } else {
            notesView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(notesView)
            NSLayoutConstraint.activate([
                notesView.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                notesView.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                notesView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
                notesView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6)
            ])
        }
        return cell
    }

    private func embed(_ field: UITextField, in cell: UITableViewCell) {
        field.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])
    }

    @objc private func save() {
        let url = (urlField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = notesView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !url.isEmpty else {
            showAlert("请先输入链接。")
            return
        }
        if title.isEmpty { title = URL(string: url)?.host ?? url }
        onSave(title, url, notes)
        navigationController?.popViewController(animated: true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
