import UIKit

final class TaskCell: UITableViewCell {
    static let reuseIdentifier = "TaskCell"

    private let glass = GlassPanelView(cornerRadius: 22)
    private let titleLabel = UILabel()
    private let noteLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusImageView = UIImageView()
    private let calendarImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(glass)
        glass.pinToEdges(of: contentView, insets: UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2

        noteLabel.font = .preferredFont(forTextStyle: .subheadline)
        noteLabel.textColor = .secondaryLabel
        noteLabel.adjustsFontForContentSizeCategory = true
        noteLabel.numberOfLines = 2

        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = .secondaryLabel
        dateLabel.adjustsFontForContentSizeCategory = true

        statusImageView.contentMode = .scaleAspectFit
        calendarImageView.contentMode = .scaleAspectFit
        calendarImageView.tintColor = .systemBlue

        let textStack = UIStackView(arrangedSubviews: [titleLabel, noteLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = 5

        let iconStack = UIStackView(arrangedSubviews: [statusImageView, calendarImageView])
        iconStack.axis = .vertical
        iconStack.alignment = .center
        iconStack.spacing = 12

        let root = UIStackView(arrangedSubviews: [iconStack, textStack])
        root.axis = .horizontal
        root.alignment = .center
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false

        glass.contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: glass.contentView.topAnchor, constant: 16),
            root.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor, constant: 16),
            root.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor, constant: -16),
            root.bottomAnchor.constraint(equalTo: glass.contentView.bottomAnchor, constant: -16),
            statusImageView.widthAnchor.constraint(equalToConstant: 26),
            statusImageView.heightAnchor.constraint(equalToConstant: 26),
            calendarImageView.widthAnchor.constraint(equalToConstant: 20),
            calendarImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with task: TaskItem) {
        titleLabel.text = task.title
        noteLabel.text = task.notes.isEmpty ? "No notes" : task.notes
        noteLabel.isHidden = task.notes.isEmpty

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: task.dueDate)

        let statusName = task.isCompleted ? "checkmark.circle.fill" : "circle"
        statusImageView.image = UIImage(systemName: statusName)
        statusImageView.tintColor = task.isCompleted ? .systemGreen : .tertiaryLabel

        calendarImageView.image = UIImage(systemName: task.calendarEventIdentifier == nil ? "calendar.badge.plus" : "calendar.badge.checkmark")
        calendarImageView.isHidden = false

        titleLabel.textColor = task.isCompleted ? .secondaryLabel : .label
        glass.alpha = task.isCompleted ? 0.68 : 1.0
    }
}
