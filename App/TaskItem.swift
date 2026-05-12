import Foundation

struct TaskItem: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var isCompleted: Bool
    var calendarEventIdentifier: String?
    var createdAt: Date
    /// Priority: 0 = none, 1 = low, 2 = medium, 3 = high
    var priority: Int

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date = Date().addingTimeInterval(86400),
        isCompleted: Bool = false,
        calendarEventIdentifier: String? = nil,
        createdAt: Date = Date(),
        priority: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.calendarEventIdentifier = calendarEventIdentifier
        self.createdAt = createdAt
        self.priority = priority
    }

    var priorityLabel: String {
        switch priority {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "None"
        }
    }

    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }
}
