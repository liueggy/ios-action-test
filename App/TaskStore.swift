import Foundation
import Combine

final class TaskStore: ObservableObject {
    static let shared = TaskStore()

    @Published var tasks: [TaskItem] = []

    private let key = "glass_tasks_v2"

    private init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            tasks = Self.demoTasks(for: AppSettings.shared.appMode)
            save()
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

    var todayTasks: [TaskItem] {
        pendingTasks.filter { Calendar.current.isDateInToday($0.dueDate) }
    }

    var overdueTasks: [TaskItem] {
        pendingTasks.filter { $0.dueDate < Date() }
    }

    var pendingCount: Int { pendingTasks.count }
    var completedCount: Int { completedTasks.count }

    var completionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    func summaryText(modeName: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines = [String]()
        lines.append("Egg Tool 摘要")
        lines.append("模式：\(modeName)")
        lines.append("待处理：\(pendingCount) 项")
        lines.append("已完成：\(completedCount) 项")
        lines.append("今日到期：\(todayTasks.count) 项")
        lines.append("逾期：\(overdueTasks.count) 项")
        lines.append("完成率：\(Int(completionRate * 100))%")
        lines.append("")

        if pendingTasks.isEmpty {
            lines.append("当前没有待处理任务。")
        } else {
            lines.append("最近待处理任务：")
            for (index, task) in pendingTasks.prefix(5).enumerated() {
                lines.append("\(index + 1). \(task.title) - \(formatter.string(from: task.dueDate))")
            }
            if pendingTasks.count > 5 {
                lines.append("其余 \(pendingTasks.count - 5) 项请在 App 内查看。")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func demoTasks(for mode: AppMode) -> [TaskItem] {
        let now = Date()
        switch mode {
        case .study:
            return [
                TaskItem(title: "完成机械设计作业", notes: "检查公式与图示", dueDate: now.addingTimeInterval(7200), priority: 3),
                TaskItem(title: "复习嵌入式串口通信", notes: "HAL_UART_Transmit 与接收流程", dueDate: now.addingTimeInterval(86400), priority: 2),
                TaskItem(title: "整理 Robocon 备赛计划", notes: "列出传感器与控制模块", dueDate: now.addingTimeInterval(172800), priority: 2)
            ]
        case .work:
            return [
                TaskItem(title: "跟进项目排期", notes: "确认本周里程碑", dueDate: now.addingTimeInterval(10800), priority: 3),
                TaskItem(title: "准备会议纪要", notes: "输出任务分工", dueDate: now.addingTimeInterval(43200), priority: 2),
                TaskItem(title: "回顾待处理事项", notes: "清理积压任务", dueDate: now.addingTimeInterval(90000), priority: 1)
            ]
        case .life:
            return [
                TaskItem(title: "采购生活用品", notes: "洗衣液、纸巾、牛奶", dueDate: now.addingTimeInterval(14400), priority: 1),
                TaskItem(title: "晚间散步 30 分钟", notes: "保持运动", dueDate: now.addingTimeInterval(36000), priority: 1),
                TaskItem(title: "给家里打电话", notes: "周末联系家人", dueDate: now.addingTimeInterval(86400), priority: 2)
            ]
        case .default:
            return [
                TaskItem(title: "整理今天的重点任务", notes: "先做最重要的 1 件事", dueDate: now.addingTimeInterval(3600), priority: 2),
                TaskItem(title: "把一个任务写入日历", notes: "体验原生联动功能", dueDate: now.addingTimeInterval(28800), priority: 1),
                TaskItem(title: "打开快捷操作页试试看", notes: "体验短信、网页、地图与摘要分享", dueDate: now.addingTimeInterval(86400), priority: 1)
            ]
        }
    }
}
