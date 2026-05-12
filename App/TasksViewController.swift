import UIKit

final class TasksViewController: UITableViewController {
    private let store = TaskStore()
    private let filters = ["待处理", "已完成", "全部"]
    private var selectedFilter = 0

    private lazy var filterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: filters)
        control.selectedSegmentIndex = selectedFilter
        control.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        return control
    }()

    private var filteredTasks: [TaskItem] {
        switch selectedFilter {
        case 0: return store.pendingTasks
        case 1: return store.completedTasks
        default: return store.tasks.sorted { $0.dueDate < $1.dueDate }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "玻璃待办"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareSummary))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .singleLine
        configureHeader()

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refreshControl = refresh
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.prompt = "当前模式：\(AppSettings.shared.appMode.displayName)"
        tableView.reloadData()
    }

    private func configureHeader() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 56))
        filterControl.frame = CGRect(x: 16, y: 8, width: max(view.bounds.width - 32, 200), height: 34)
        filterControl.autoresizingMask = [.flexibleWidth]
        container.addSubview(filterControl)
        tableView.tableHeaderView = container
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 2 }
        return max(filteredTasks.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "总览" : "任务列表"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default
        cell.backgroundColor = .secondarySystemGroupedBackground

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                var content = UIListContentConfiguration.valueCell()
                content.text = "待处理：\(store.pendingCount)"
                content.secondaryText = "已完成：\(store.completedCount) · 今日：\(store.todayTasks.count) · 逾期：\(store.overdueTasks.count)"
                content.image = UIImage(systemName: "sparkles")
                cell.contentConfiguration = content
            } else {
                var content = UIListContentConfiguration.subtitleCell()
                content.text = "当前模式：\(AppSettings.shared.appMode.displayName)"
                content.secondaryText = "\(AppSettings.shared.appMode.descriptionText)\n完成率：\(Int(store.completionRate * 100))%"
                content.secondaryTextProperties.numberOfLines = 2
                content.image = UIImage(systemName: "slider.horizontal.3")
                cell.contentConfiguration = content
                cell.selectionStyle = .none
            }
            return cell
        }

        guard !filteredTasks.isEmpty else {
            var content = UIListContentConfiguration.cell()
            content.text = "暂无任务"
            content.secondaryText = "点击右上角 + 创建一个新的任务"
            content.image = UIImage(systemName: "checkmark.circle")
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            return cell
        }

        let task = filteredTasks[indexPath.row]
        var content = UIListContentConfiguration.subtitleCell()
        content.text = task.title
        content.secondaryText = subtitle(for: task)
        content.secondaryTextProperties.numberOfLines = 2
        content.image = UIImage(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
        content.imageProperties.tintColor = task.isCompleted ? .systemGreen : (task.isOverdue ? .systemRed : .secondaryLabel)
        cell.contentConfiguration = content

        let calendarButton = UIButton(type: .system)
        calendarButton.setImage(UIImage(systemName: task.calendarEventIdentifier == nil ? "calendar.badge.plus" : "calendar.badge.checkmark"), for: .normal)
        calendarButton.tintColor = .systemBlue
        calendarButton.tag = indexPath.row
        calendarButton.addTarget(self, action: #selector(addTaskToCalendar(_:)), for: .touchUpInside)
        cell.accessoryView = calendarButton
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1, !filteredTasks.isEmpty else { return }
        let task = filteredTasks[indexPath.row]
        store.toggleComplete(task)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, indexPath.section == 1, !filteredTasks.isEmpty else { return }
        let task = filteredTasks[indexPath.row]
        if let id = task.calendarEventIdentifier {
            CalendarService.shared.removeFromCalendar(identifier: id)
        }
        store.delete(task)
        tableView.reloadData()
    }

    private func subtitle(for task: TaskItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        var parts = [formatter.string(from: task.dueDate)]
        if task.priority > 0 { parts.append("优先级：\(task.priorityLabel)") }
        if task.isOverdue { parts.append("已逾期") }
        if !task.notes.isEmpty { parts.append(task.notes) }
        return parts.joined(separator: " · ")
    }

    @objc private func filterChanged(_ sender: UISegmentedControl) {
        selectedFilter = sender.selectedSegmentIndex
        tableView.reloadData()
    }

    @objc private func refreshData() {
        tableView.reloadData()
        refreshControl?.endRefreshing()
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
            guard let self else { return }
            var newTask = task
            if shouldCalendar {
                Swift.Task {
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

    @objc private func addTaskToCalendar(_ sender: UIButton) {
        guard sender.tag < filteredTasks.count else { return }
        let task = filteredTasks[sender.tag]
        Swift.Task {
            if let id = await CalendarService.shared.addToCalendar(task: task) {
                var updated = task
                updated.calendarEventIdentifier = id
                await MainActor.run {
                    self.store.update(updated)
                    self.tableView.reloadData()
                }
            }
        }
    }
}
