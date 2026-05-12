import Foundation

struct TaskItem: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var isCompleted: Bool
    var calendarEventIdentifier: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date,
        isCompleted: Bool = false,
        calendarEventIdentifier: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.calendarEventIdentifier = calendarEventIdentifier
        self.createdAt = createdAt
    }
}
