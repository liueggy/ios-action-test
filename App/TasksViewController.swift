import UIKit

final class TasksViewController: UITableViewController {
    private let store = TaskStore()
    private let filters = ["Pending", "Done", "All"]
    private var selectedFilter = 0

    private var filteredTasks: [TaskItem] {
        switch selectedFilter {
        case 0: return store.pendingTasks
        case 1: return store.completedTasks
        default: return store.tasks.sorted { $0.dueDate < $1.dueDate }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Glass Tasks"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .singleLine

        let control = UISegmentedControl(items: filters)
        control.selectedSegmentIndex = selectedFilter
        control.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        navigationItem.titleView = control
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return max(filteredTasks.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Overview" : "Tasks"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default
        cell.backgroundColor = .secondarySystemGroupedBackground

        if indexPath.section == 0 {
            var content = UIListContentConfiguration.valueCell()
            content.text = "Pending: \(store.pendingCount)"
            content.secondaryText = "Done: \(store.completedCount)"
            content.image = UIImage(systemName: "sparkles")
            cell.contentConfiguration = content
            return cell
        }

        guard !filteredTasks.isEmpty else {
            var content = UIListContentConfiguration.cell()
            content.text = "No tasks"
            content.secondaryText = "Tap + to add one"
            content.image = UIImage(systemName: "checkmark.circle")
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            return cell
        }

        let task = filteredTasks[indexPath.row]
        var content = UIListContentConfiguration.subtitleCell()
        content.text = task.title
        content.secondaryText = subtitle(for: task)
        content.image = UIImage(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
        content.imageProperties.tintColor = task.isCompleted ? .systemGreen : .secondaryLabel
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
        if let id = task.calendarEventIdentifier { CalendarService.shared.removeFromCalendar(identifier: id) }
        store.delete(task)
        tableView.reloadData()
    }

    private func subtitle(for task: TaskItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        var parts = [formatter.string(from: task.dueDate)]
        if task.priority > 0 { parts.append("Priority: \(task.priorityLabel)") }
        if !task.notes.isEmpty { parts.append(task.notes) }
        return parts.joined(separator: " · ")
    }

    @objc private func filterChanged(_ sender: UISegmentedControl) {
        selectedFilter = sender.selectedSegmentIndex
        tableView.reloadData()
    }

    @objc private func addTask() {
        let controller = AddTaskViewController()
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
