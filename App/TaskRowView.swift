import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject var store: TaskStore
    let task: TaskItem
    @State private var isAddingToCalendar = false

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    store.toggleComplete(task)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .symbolEffect(.bounce, value: task.isCompleted)
            }
            .buttonStyle(.plain)

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    // Due date
                    Label(formattedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)

                    // Priority badge
                    if task.priority > 0 {
                        Text(task.priorityLabel)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(priorityColor)
                    }

                    // Calendar indicator
                    if task.calendarEventIdentifier != nil {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Add to calendar button
            if task.calendarEventIdentifier == nil && !task.isCompleted {
                Button(action: { addToCalendar() }) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.body)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(isAddingToCalendar)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(task.dueDate) {
            formatter.dateFormat = "'Today' HH:mm"
        } else if calendar.isDateInTomorrow(task.dueDate) {
            formatter.dateFormat = "'Tomorrow' HH:mm"
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
        }
        return formatter.string(from: task.dueDate)
    }

    private var priorityColor: Color {
        switch task.priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .gray
        }
    }

    private func addToCalendar() {
        isAddingToCalendar = true
        Task {
            if let eventId = await CalendarService.shared.addToCalendar(task: task) {
                var updated = task
                updated.calendarEventIdentifier = eventId
                store.update(updated)
            }
            isAddingToCalendar = false
        }
    }
}
