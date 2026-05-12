import UIKit
import UniformTypeIdentifiers

struct EggToolBackup: Codable {
    var version: Int
    var exportedAt: Date
    var tasks: [TaskItem]
    var notes: [NoteItem]
    var links: [LinkItem]
}

final class BackupViewController: UITableViewController, UIDocumentPickerDelegate {
    private enum Row: Int, CaseIterable {
        case export
        case `import`
        case summary

        var title: String {
            switch self {
            case .export: return "导出 JSON 备份"
            case .import: return "从 JSON 备份导入"
            case .summary: return "当前数据概览"
            }
        }

        var subtitle: String {
            switch self {
            case .export: return "导出任务、笔记和链接，便于备份或迁移"
            case .import: return "选择之前导出的 Egg Tool JSON 文件恢复数据"
            case .summary: return "查看当前任务、笔记和链接数量"
            }
        }

        var icon: String {
            switch self {
            case .export: return "square.and.arrow.up"
            case .import: return "square.and.arrow.down"
            case .summary: return "chart.bar.doc.horizontal"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "数据备份"
        navigationItem.largeTitleDisplayMode = .always
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(EggCardCell.self, forCellReuseIdentifier: EggCardCell.reuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Row.allCases.count }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "导入会覆盖当前本机任务、笔记和链接。建议先导出现有备份再导入。"
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 92 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row.allCases[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: EggCardCell.reuseIdentifier, for: indexPath) as! EggCardCell
        cell.configure(
            title: row.title,
            subtitle: row == .summary ? currentSummary() : row.subtitle,
            icon: row.icon,
            tint: tint(for: row),
            showsChevron: true
        )
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Row.allCases[indexPath.row] {
        case .export: exportBackup()
        case .import: confirmImport()
        case .summary: showSummary()
        }
    }

    private func tint(for row: Row) -> UIColor {
        switch row {
        case .export: return AppSettings.shared.accentStyle.tintColor
        case .import: return .systemOrange
        case .summary: return .systemPurple
        }
    }

    private func currentBackup() -> EggToolBackup {
        EggToolBackup(
            version: 1,
            exportedAt: Date(),
            tasks: TaskStore.shared.tasks,
            notes: NoteStore.shared.notes,
            links: LinkStore.shared.links
        )
    }

    private func currentSummary() -> String {
        "任务 \(TaskStore.shared.tasks.count) · 笔记 \(NoteStore.shared.notes.count) · 链接 \(LinkStore.shared.links.count)"
    }

    private func exportBackup() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(currentBackup())
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let name = "EggTool-Backup-\(formatter.string(from: Date())).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)

            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            controller.popoverPresentationController?.sourceView = tableView
            present(controller, animated: true)
        } catch {
            showAlert(title: "导出失败", message: error.localizedDescription)
        }
    }

    private func confirmImport() {
        let alert = UIAlertController(title: "导入备份", message: "导入会覆盖当前任务、笔记和链接。建议先导出现有备份。是否继续？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "继续", style: .destructive) { [weak self] _ in
            self?.openImporter()
        })
        present(alert, animated: true)
    }

    private func openImporter() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(EggToolBackup.self, from: data)
            TaskStore.shared.replaceAll(backup.tasks)
            NoteStore.shared.replaceAll(backup.notes)
            LinkStore.shared.replaceAll(backup.links)
            tableView.reloadData()
            showAlert(title: "导入完成", message: "已恢复：任务 \(backup.tasks.count) · 笔记 \(backup.notes.count) · 链接 \(backup.links.count)")
        } catch {
            showAlert(title: "导入失败", message: "无法读取该备份文件：\n\(error.localizedDescription)")
        }
    }

    private func showSummary() {
        let message = "任务：\(TaskStore.shared.tasks.count)\n笔记：\(NoteStore.shared.notes.count)\n链接：\(LinkStore.shared.links.count)"
        showAlert(title: "当前数据", message: message)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
