import Foundation

struct NoteItem: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }
}

final class NoteStore {
    static let shared = NoteStore()

    private let key = "egg_tool_notes_v1"
    private(set) var notes: [NoteItem] = []

    private init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([NoteItem].self, from: data) else {
            notes = []
            return
        }
        notes = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(title: String, body: String) {
        let note = NoteItem(title: title, body: body)
        notes.insert(note, at: 0)
        sortNotes()
        save()
    }

    func update(_ note: NoteItem, title: String, body: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].title = title
        notes[index].body = body
        notes[index].updatedAt = Date()
        sortNotes()
        save()
    }

    func delete(_ note: NoteItem) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    func togglePinned(_ note: NoteItem) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isPinned.toggle()
        notes[index].updatedAt = Date()
        sortNotes()
        save()
    }

    func filtered(keyword: String) -> [NoteItem] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return notes }
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.body.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func sortNotes() {
        notes.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
}
