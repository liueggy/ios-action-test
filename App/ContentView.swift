import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TaskStore
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .pending

    enum TaskFilter: String, CaseIterable, Hashable {
        case pending = "Pending"
        case completed = "Completed"
        case all = "All"
    }

    var filteredTasks: [TaskItem] {
        switch selectedFilter {
        case .pending: return store.pendingTasks
        case .completed: return store.completedTasks
        case .all: return store.tasks.sorted { $0.dueDate < $1.dueDate }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("Glass Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            StatCard(title: "Pending", count: store.pendingCount, color: .orange)
            StatCard(title: "Done", count: store.completedCount, color: .green)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text(selectedFilter == .pending ? "No pending tasks" : "No tasks yet")
                .font(.title3)
                .foregroundColor(.secondary)
            if selectedFilter == .pending {
                Text("Tap + to add a new task")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var taskListView: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskRowView(task: task)
            }
            .onDelete { offsets in
                let tasksToDelete = offsets.map { filteredTasks[$0] }
                for task in tasksToDelete {
                    if let eventId = task.calendarEventIdentifier {
                        CalendarService.shared.removeFromCalendar(identifier: eventId)
                    }
                    store.delete(task)
                }
            }
        }
        .listStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
