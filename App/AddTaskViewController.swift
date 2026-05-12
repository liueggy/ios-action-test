import UIKit

final class AddTaskViewController: UIViewController {
    var onSave: ((TaskItem) -> Void)?

    private let titleField = UITextField()
    private let notesView = UITextView()
    private let datePicker = UIDatePicker()
    private let panel = GlassPanelView(cornerRadius: 28)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Task"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in
            self?.save()
        })
        setupUI()
    }

    private func setupUI() {
        let background = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        view.addSubview(background)
        background.pinToEdges(of: view)

        view.addSubview(panel)
        panel.translatesAutoresizingMaskIntoConstraints = false

        titleField.placeholder = "Task title"
        titleField.borderStyle = .roundedRect
        titleField.textContentType = .none
        titleField.font = .preferredFont(forTextStyle: .body)
        titleField.adjustsFontForContentSizeCategory = true

        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.adjustsFontForContentSizeCategory = true
        notesView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.75)
        notesView.layer.cornerRadius = 14
        notesView.layer.cornerCurve = .continuous
        notesView.text = ""

        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .inline
        datePicker.minimumDate = Date().addingTimeInterval(-60)
        datePicker.date = Date().addingTimeInterval(3600)

        let noteLabel = UILabel()
        noteLabel.text = "Notes"
        noteLabel.font = .preferredFont(forTextStyle: .headline)

        let dueLabel = UILabel()
        dueLabel.text = "Due Date"
        dueLabel.font = .preferredFont(forTextStyle: .headline)

        let stack = UIStackView(arrangedSubviews: [titleField, noteLabel, notesView, dueLabel, datePicker])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),

            stack.topAnchor.constraint(equalTo: panel.contentView.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: panel.contentView.bottomAnchor, constant: -18),
            notesView.heightAnchor.constraint(equalToConstant: 110)
        ])
    }

    private func save() {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else {
            let alert = UIAlertController(title: "Title Required", message: "Please enter a task title.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let task = TaskItem(title: title, notes: notesView.text.trimmingCharacters(in: .whitespacesAndNewlines), dueDate: datePicker.date)
        onSave?(task)
        dismiss(animated: true)
    }
}
