import Foundation
import Combine

final class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []

    private let key = "glass_tasks_v2"

    init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            return
        }
        tasks = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ task: TaskItem) {
        tasks.insert(task, at: 0)
        save()
    }

    func update(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard tasks.indices.contains(index) else { continue }
            tasks.remove(at: index)
        }
        save()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func toggleComplete(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        save()
    }

    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }.sorted { $0.dueDate < $1.dueDate }
    }

    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }.sorted { $0.dueDate > $1.dueDate }
    }

    var pendingCount: Int { pendingTasks.count }
    var completedCount: Int { completedTasks.count }
}
