import EventKit
import Foundation

final class CalendarService {
    static let shared = CalendarService()
    private let store = EKEventStore()

    private init() {}

    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func addToCalendar(task: TaskItem) async -> String? {
        let granted = await requestAccess()
        guard granted else { return nil }

        let event = EKEvent(eventStore: store)
        event.title = task.title
        event.notes = task.notes.isEmpty ? nil : task.notes
        event.startDate = task.dueDate
        event.endDate = task.dueDate.addingTimeInterval(3600)
        event.calendar = store.defaultCalendarForNewEvents

        if task.priority >= 2 {
            let alarm = EKAlarm(relativeOffset: -900) // 15 min before
            event.addAlarm(alarm)
        }

        do {
            try store.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            return nil
        }
    }

    func removeFromCalendar(identifier: String) {
        guard let event = store.event(withIdentifier: identifier) else { return }
        try? store.remove(event, span: .thisEvent)
    }
}
