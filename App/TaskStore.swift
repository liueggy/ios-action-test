import Foundation

final class TaskStore {
    static let shared = TaskStore()

    private let storageKey = "glass.tasks.items.v1"
    private(set) var tasks: [TaskItem] = []

    private init() {
        load()
        if tasks.isEmpty {
            tasks = [
                TaskItem(title: "Try Glass Tasks", notes: "Add this sample task to Calendar, then mark it complete.", dueDate: Date().addingTimeInterval(3600))
            ]
            save()
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            tasks = []
            return
        }

        do {
            tasks = try JSONDecoder().decode([TaskItem].self, from: data)
                .sorted { $0.dueDate < $1.dueDate }
        } catch {
            tasks = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save tasks: \(error)")
        }
    }

    func add(_ task: TaskItem) {
        tasks.append(task)
        sortAndSave()
    }

    func update(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        sortAndSave()
    }

    func delete(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        save()
    }

    func toggleComplete(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        sortAndSave()
    }

    private func sortAndSave() {
        tasks.sort { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted && rhs.isCompleted
            }
            return lhs.dueDate < rhs.dueDate
        }
        save()
    }
}
