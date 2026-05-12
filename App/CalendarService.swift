import EventKit
import UIKit

final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()

    private init() {}

    func addTaskToCalendar(_ task: TaskItem, from presenter: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        requestAccess { [weak self] granted, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard granted else {
                DispatchQueue.main.async {
                    completion(.failure(CalendarError.permissionDenied))
                }
                return
            }

            let event = EKEvent(eventStore: self.store)
            event.title = task.title
            event.notes = task.notes.isEmpty ? "Created by Glass Tasks" : task.notes
            event.startDate = task.dueDate
            event.endDate = task.dueDate.addingTimeInterval(30 * 60)
            event.calendar = self.store.defaultCalendarForNewEvents
            event.alarms = [EKAlarm(relativeOffset: -15 * 60)]

            do {
                try self.store.save(event, span: .thisEvent, commit: true)
                DispatchQueue.main.async { completion(.success(event.eventIdentifier)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    private func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            store.requestWriteOnlyAccessToEvents(completion: completion)
        } else {
            store.requestAccess(to: .event, completion: completion)
        }
    }
}

enum CalendarError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar access was denied. Enable Calendar permission in Settings."
        }
    }
}
