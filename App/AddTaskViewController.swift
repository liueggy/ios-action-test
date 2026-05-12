import UIKit

final class AddTaskViewController: UITableViewController {
    var onSave: ((TaskItem, Bool) -> Void)?

    private let titleField = UITextField()
    private let notesField = UITextField()
    private let datePicker = UIDatePicker()
    private let prioritySlider = UISlider()
    private let priorityLabel = UILabel()
    private let calendarSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Task"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground

        titleField.placeholder = "Task title"
        titleField.clearButtonMode = .whileEditing

        notesField.placeholder = "Notes optional"
        notesField.clearButtonMode = .whileEditing

        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        datePicker.date = Date().addingTimeInterval(86400)

        prioritySlider.minimumValue = 0
        prioritySlider.maximumValue = 3
        prioritySlider.value = 0
        prioritySlider.isContinuous = true
        prioritySlider.addTarget(self, action: #selector(priorityChanged), for: .valueChanged)

        priorityLabel.text = "None"
        priorityLabel.textColor = .secondaryLabel
        calendarSwitch.isOn = true
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 2
        default: return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Task"
        case 1: return "Schedule"
        default: return "Integration"
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .secondarySystemGroupedBackground

        if indexPath.section == 0 && indexPath.row == 0 {
            cell.contentView.addSubview(titleField)
            titleField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                titleField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                titleField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                titleField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
        } else if indexPath.section == 0 {
            cell.contentView.addSubview(notesField)
            notesField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                notesField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                notesField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                notesField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                notesField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
        } else if indexPath.section == 1 && indexPath.row == 0 {
            cell.textLabel?.text = "Due date"
            cell.accessoryView = datePicker
        } else if indexPath.section == 1 {
            cell.textLabel?.text = "Priority"
            let stack = UIStackView(arrangedSubviews: [prioritySlider, priorityLabel])
            stack.axis = .horizontal
            stack.spacing = 10
            stack.frame = CGRect(x: 0, y: 0, width: 180, height: 32)
            priorityLabel.widthAnchor.constraint(equalToConstant: 62).isActive = true
            cell.accessoryView = stack
        } else {
            cell.textLabel?.text = "Add to Calendar"
            cell.accessoryView = calendarSwitch
        }
        return cell
    }

    @objc private func priorityChanged() {
        let value = Int(prioritySlider.value.rounded())
        prioritySlider.value = Float(value)
        switch value {
        case 1:
            priorityLabel.text = "Low"
            priorityLabel.textColor = .systemBlue
        case 2:
            priorityLabel.text = "Medium"
            priorityLabel.textColor = .systemOrange
        case 3:
            priorityLabel.text = "High"
            priorityLabel.textColor = .systemRed
        default:
            priorityLabel.text = "None"
            priorityLabel.textColor = .secondaryLabel
        }
    }

    @objc private func cancel() { dismiss(animated: true) }

    @objc private func save() {
        let title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let task = TaskItem(
            title: title,
            notes: (notesField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: datePicker.date,
            priority: Int(prioritySlider.value.rounded())
        )
        onSave?(task, calendarSwitch.isOn)
        dismiss(animated: true)
    }
}
