import UIKit
import UniformTypeIdentifiers
import QuickLook

final class ReaderViewController: UITableViewController, UISearchResultsUpdating, UIDocumentPickerDelegate, QLPreviewControllerDataSource {
    private let store = ReaderStore.shared
    private let searchController = UISearchController(searchResultsController: nil)
    private var keyword = ""
    private var previewURL: URL?

    private var visibleItems: [ReaderItem] { store.filtered(keyword: keyword) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "阅读器"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importFile))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(EggCardCell.self, forCellReuseIdentifier: EggCardCell.reuseIdentifier)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索书名、文件名或格式"
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
        max(visibleItems.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "支持 TXT、Markdown、JSON、常见代码/配置文件、图片、PDF、Office/iWork、EPUB/MOBI/AZW/CBZ 等电子书。文本类使用内置阅读器，其他格式使用系统 Quick Look。"
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        visibleItems.isEmpty ? UITableView.automaticDimension : 92
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !visibleItems.isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var content = UIListContentConfiguration.subtitleCell()
            content.text = keyword.isEmpty ? "还没有导入文档" : "没有匹配的文档"
            content.secondaryText = keyword.isEmpty ? "点击右上角 + 导入 PDF、TXT、Markdown、图片或 Office 文件" : "换个关键词试试"
            content.image = UIImage(systemName: "books.vertical")
            content.imageProperties.tintColor = AppSettings.shared.accentStyle.tintColor
            cell.contentConfiguration = content
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.selectionStyle = .none
            return cell
        }

        let item = visibleItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: EggCardCell.reuseIdentifier, for: indexPath) as! EggCardCell
        cell.configure(
            title: item.title,
            subtitle: "\(item.originalName) · \(displayKind(for: item))",
            icon: icon(for: item),
            tint: tint(for: item),
            trailing: item.isPinned ? "置顶" : item.fileExtension.uppercased(),
            showsChevron: true
        )
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !visibleItems.isEmpty else { return }
        open(visibleItems[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !visibleItems.isEmpty else { return nil }
        let item = visibleItems[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            self?.store.delete(item)
            self?.tableView.reloadData()
            done(true)
        }
        let pin = UIContextualAction(style: .normal, title: item.isPinned ? "取消置顶" : "置顶") { [weak self] _, _, done in
            self?.store.togglePinned(item)
            self?.tableView.reloadData()
            done(true)
        }
        pin.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [delete, pin])
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !visibleItems.isEmpty else { return nil }
        let item = visibleItems[indexPath.row]
        let share = UIContextualAction(style: .normal, title: "分享") { [weak self] _, _, done in
            self?.share(item)
            done(true)
        }
        share.backgroundColor = .systemGreen
        let rename = UIContextualAction(style: .normal, title: "重命名") { [weak self] _, _, done in
            self?.rename(item)
            done(true)
        }
        rename.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [share, rename])
    }

    @objc private func importFile() {
        let types: [UTType] = [.data, .text, .pdf, .image, .item, .content, .archive]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var imported = 0
        var failed = 0
        for url in urls {
            do {
                try store.importFile(from: url)
                imported += 1
            } catch {
                failed += 1
            }
        }
        tableView.reloadData()
        showAlert(title: "导入完成", message: failed == 0 ? "已导入 \(imported) 个文件。" : "已导入 \(imported) 个文件，失败 \(failed) 个。")
    }

    private func open(_ item: ReaderItem) {
        let url = store.fileURL(for: item)
        switch ReaderFileKind.kind(for: item.fileExtension) {
        case .text:
            let controller = TextReaderViewController(item: item, url: url)
            navigationController?.pushViewController(controller, animated: true)
        case .image:
            let controller = ImageReaderViewController(item: item, url: url)
            navigationController?.pushViewController(controller, animated: true)
        case .ebook:
            previewURL = url
            let controller = QLPreviewController()
            controller.dataSource = self
            navigationController?.pushViewController(controller, animated: true)
        case .quickLook:
            previewURL = url
            let controller = QLPreviewController()
            controller.dataSource = self
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func share(_ item: ReaderItem) {
        let url = store.fileURL(for: item)
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = tableView
        present(controller, animated: true)
    }

    private func rename(_ item: ReaderItem) {
        let alert = UIAlertController(title: "重命名", message: item.originalName, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = item.title
            field.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            let title = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else { return }
            self?.store.rename(item, title: title)
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { previewURL == nil ? 0 : 1 }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewURL! as NSURL
    }

    private func icon(for item: ReaderItem) -> String {
        switch ReaderFileKind.kind(for: item.fileExtension) {
        case .text: return item.isPinned ? "pin.fill" : "doc.text.fill"
        case .image: return item.isPinned ? "pin.fill" : "photo.fill"
        case .ebook: return item.isPinned ? "pin.fill" : "book.closed.fill"
        case .quickLook: return item.isPinned ? "pin.fill" : "doc.richtext.fill"
        }
    }

    private func tint(for item: ReaderItem) -> UIColor {
        if item.isPinned { return .systemOrange }
        switch ReaderFileKind.kind(for: item.fileExtension) {
        case .text: return AppSettings.shared.accentStyle.tintColor
        case .image: return .systemPink
        case .ebook: return .systemBrown
        case .quickLook: return .systemIndigo
        }
    }

    private func displayKind(for item: ReaderItem) -> String {
        switch ReaderFileKind.kind(for: item.fileExtension) {
        case .text: return "内置文本阅读"
        case .image: return "图片阅读"
        case .ebook: return "电子书 / 系统预览"
        case .quickLook: return "Quick Look 预览"
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
