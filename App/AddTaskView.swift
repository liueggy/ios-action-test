import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var priority: Int = 0
    @State private var addToCalendar = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                        .font(.body)

                    TextField("Notes optional", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                } header: {
                    Text("Task")
                }

                Section {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Priority")
                            Spacer()
                            Text(priorityLabel)
                                .foregroundColor(priorityColor)
                                .fontWeight(.medium)
                        }
                        Slider(value: priorityBinding, in: 0...3, step: 1) {
                            Text("Priority")
                        } minimumValueLabel: {
                            Image(systemName: "minus")
                                .font(.caption2)
                        } maximumValueLabel: {
                            Image(systemName: "exclamationmark.3")
                                .font(.caption2)
                        }
                        .tint(priorityColor)
                    }
                } header: {
                    Text("Schedule")
                }

                Section {
                    Toggle("Add to Calendar", isOn: $addToCalendar)
                } header: {
                    Text("Integration")
                } footer: {
                    Text("Creates an event in your system calendar with a reminder.")
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveTask() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private var priorityBinding: Binding<Double> {
        Binding(
            get: { Double(priority) },
            set: { priority = Int($0) }
        )
    }

    private var priorityLabel: String {
        switch priority {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "None"
        }
    }

    private var priorityColor: Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .secondary
        }
    }

    private func saveTask() {
        isSaving = true
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            isSaving = false
            return
        }

        var newTask = TaskItem(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            priority: priority
        )

        if addToCalendar {
            Swift.Task {
                if let eventId = await CalendarService.shared.addToCalendar(task: newTask) {
                    newTask.calendarEventIdentifier = eventId
                }
                await MainActor.run {
                    store.add(newTask)
                    dismiss()
                }
            }
        } else {
            store.add(newTask)
            dismiss()
        }
    }
}
