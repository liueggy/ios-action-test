import UIKit

final class TasksViewController: UITableViewController {
    private let store = TaskStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Glass Tasks"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112

        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            self?.presentAddTask()
        })

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func presentAddTask() {
        let addVC = AddTaskViewController()
        addVC.onSave = { [weak self] task in
            self?.store.add(task)
            self?.tableView.reloadData()
        }
        let nav = UINavigationController(rootViewController: addVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.tasks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier, for: indexPath) as! TaskCell
        cell.configure(with: store.tasks[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = store.tasks[indexPath.row]
        let alert = UIAlertController(title: task.title, message: "Choose an action", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: task.isCompleted ? "Mark as Not Done" : "Mark as Done", style: .default) { [weak self] _ in
            self?.store.toggleComplete(id: task.id)
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: task.calendarEventIdentifier == nil ? "Add to Calendar" : "Add Again to Calendar", style: .default) { [weak self] _ in
            self?.addToCalendar(task, at: indexPath.row)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView.cellForRow(at: indexPath)
            popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
        }
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.store.delete(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func addToCalendar(_ task: TaskItem, at index: Int) {
        CalendarService.shared.addTaskToCalendar(task, from: self) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let identifier):
                var updated = task
                updated.calendarEventIdentifier = identifier
                self.store.update(updated)
                self.tableView.reloadData()
                self.showMessage(title: "Added to Calendar", message: "The task has been added to your system calendar.")
            case .failure(let error):
                self.showMessage(title: "Calendar Error", message: error.localizedDescription)
            }
        }
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
