import UIKit
import SwiftUI

final class DashboardViewController: UITableViewController {
    private let store = TaskStore.shared

    private enum Section: Int, CaseIterable {
        case hero
        case metrics
        case quickCapture
        case upcoming
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "今日"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareSummary))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(SwiftUIHeroCell.self, forCellReuseIdentifier: SwiftUIHeroCell.reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: .appSettingsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .hero: return 1
        case .metrics: return 2
        case .quickCapture: return 3
        case .upcoming: return max(min(store.pendingTasks.count, 3), 1)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .hero: return nil
        case .metrics: return "今日概览"
        case .quickCapture: return "快速入口"
        case .upcoming: return "接下来"
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return UITableView.automaticDimension }
        switch section {
        case .hero: return 220
        case .metrics: return 76
        case .quickCapture: return 64
        case .upcoming: return 78
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        }

        if section == .hero {
            let heroCell = tableView.dequeueReusableCell(withIdentifier: SwiftUIHeroCell.reuseIdentifier, for: indexPath) as! SwiftUIHeroCell
            let view = EggHeroCardView(
                greeting: greeting(),
                modeName: AppSettings.shared.appMode.displayName,
                completionRate: Int(store.completionRate * 100),
                pendingCount: store.pendingCount,
                todayCount: store.todayTasks.count,
                overdueCount: store.overdueTasks.count,
                accent: Color(uiColor: AppSettings.shared.accentStyle.tintColor)
            )
            heroCell.configure(view: view, parent: self)
            return heroCell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .none
        cell.accessoryView = nil
        cell.selectionStyle = .default
        cell.backgroundColor = .clear
        cell.contentConfiguration = nil

        switch section {
        case .hero:
            configureHero(cell)
        case .metrics:
            configureMetric(cell, row: indexPath.row)
        case .quickCapture:
            configureQuickEntry(cell, row: indexPath.row)
        case .upcoming:
            configureUpcoming(cell, row: indexPath.row)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .quickCapture:
            if indexPath.row == 0 { addTask() }
            if indexPath.row == 1 {
                let controller = NotesViewController(style: .insetGrouped)
                navigationController?.pushViewController(controller, animated: true)
            }
            if indexPath.row == 2 {
                let controller = LinksViewController(style: .insetGrouped)
                navigationController?.pushViewController(controller, animated: true)
            }
        case .upcoming:
            guard !store.pendingTasks.isEmpty else { return }
            let controller = TasksViewController(style: .insetGrouped)
            navigationController?.pushViewController(controller, animated: true)
        default:
            break
        }
    }

    private func configureHero(_ cell: UITableViewCell) {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = "Egg Tool"
        content.textProperties.font = .preferredFont(forTextStyle: .largeTitle)
        content.textProperties.color = .label
        content.secondaryText = "\(greeting())，今天也保持清晰。\n当前模式：\(AppSettings.shared.appMode.displayName) · 完成率 \(Int(store.completionRate * 100))%"
        content.secondaryTextProperties.numberOfLines = 2
        content.image = UIImage(systemName: "sparkles.rectangle.stack.fill")
        content.imageProperties.tintColor = AppSettings.shared.accentStyle.tintColor
        cell.contentConfiguration = content
        cell.backgroundConfiguration = cardBackground()
        cell.selectionStyle = .none
    }

    private func configureMetric(_ cell: UITableViewCell, row: Int) {
        var content = UIListContentConfiguration.valueCell()
        if row == 0 {
            content.text = "待处理"
            content.secondaryText = "\(store.pendingCount) 项"
            content.image = UIImage(systemName: "checklist")
        } else {
            content.text = "今日 / 逾期"
            content.secondaryText = "今日 \(store.todayTasks.count) · 逾期 \(store.overdueTasks.count)"
            content.image = UIImage(systemName: store.overdueTasks.isEmpty ? "calendar.badge.clock" : "exclamationmark.triangle.fill")
            content.imageProperties.tintColor = store.overdueTasks.isEmpty ? AppSettings.shared.accentStyle.tintColor : .systemRed
        }
        content.imageProperties.tintColor = content.imageProperties.tintColor ?? AppSettings.shared.accentStyle.tintColor
        cell.contentConfiguration = content
        cell.backgroundConfiguration = cardBackground()
        cell.selectionStyle = .none
    }

    private func configureQuickEntry(_ cell: UITableViewCell, row: Int) {
        let items = [
            ("新建任务", "快速捕捉一个待办", "plus.circle.fill"),
            ("快速笔记", "记录灵感、资料和临时信息", "note.text.badge.plus"),
            ("收藏链接", "保存网页、资料和参考", "link.circle.fill")
        ]
        let item = items[row]
        var content = UIListContentConfiguration.subtitleCell()
        content.text = item.0
        content.secondaryText = item.1
        content.image = UIImage(systemName: item.2)
        content.imageProperties.tintColor = AppSettings.shared.accentStyle.tintColor
        cell.contentConfiguration = content
        cell.backgroundConfiguration = cardBackground()
        cell.accessoryType = .disclosureIndicator
    }

    private func configureUpcoming(_ cell: UITableViewCell, row: Int) {
        guard !store.pendingTasks.isEmpty else {
            var content = UIListContentConfiguration.subtitleCell()
            content.text = "暂无待处理任务"
            content.secondaryText = "点击右上角 + 添加今天的第一件事"
            content.image = UIImage(systemName: "checkmark.seal.fill")
            content.imageProperties.tintColor = .systemGreen
            cell.contentConfiguration = content
            cell.backgroundConfiguration = cardBackground()
            cell.selectionStyle = .none
            return
        }

        let task = store.pendingTasks[row]
        var content = UIListContentConfiguration.subtitleCell()
        content.text = task.title
        content.secondaryText = subtitle(for: task)
        content.secondaryTextProperties.numberOfLines = 2
        content.image = UIImage(systemName: task.isOverdue ? "clock.badge.exclamationmark.fill" : "circle")
        content.imageProperties.tintColor = task.isOverdue ? .systemRed : AppSettings.shared.accentStyle.tintColor
        cell.contentConfiguration = content
        cell.backgroundConfiguration = cardBackground()
        cell.accessoryType = .disclosureIndicator
    }

    private func cardBackground() -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.listGroupedCell()
        background.backgroundColor = .secondarySystemGroupedBackground
        background.cornerRadius = 18
        background.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
        return background
    }

    private func subtitle(for task: TaskItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        var parts = [formatter.string(from: task.dueDate)]
        if task.priority > 0 { parts.append("优先级：\(task.priorityLabel)") }
        if task.isOverdue { parts.append("已逾期") }
        return parts.joined(separator: " · ")
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }

    @objc private func reloadContent() {
        tableView.reloadData()
    }

    @objc private func shareSummary() {
        let text = store.summaryText(modeName: AppSettings.shared.appMode.displayName)
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(controller, animated: true)
    }

    @objc private func addTask() {
        let controller = AddTaskViewController(style: .insetGrouped)
        controller.onSave = { [weak self] task, shouldCalendar in
            guard let self = self else { return }
            var newTask = task
            if shouldCalendar {
                Task {
                    if let id = await CalendarService.shared.addToCalendar(task: newTask) {
                        newTask.calendarEventIdentifier = id
                    }
                    await MainActor.run {
                        self.store.add(newTask)
                        self.tableView.reloadData()
                    }
                }
            } else {
                self.store.add(newTask)
                self.tableView.reloadData()
            }
        }
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true)
    }

    private func showComingSoon(_ feature: String) {
        let alert = UIAlertController(title: feature, message: "这个入口已经预留，会在 Egg Tool 后续版本中扩展。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}
