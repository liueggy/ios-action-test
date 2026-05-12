import Foundation

struct LinkItem: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var urlString: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), title: String, urlString: String, notes: String = "", createdAt: Date = Date(), updatedAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }

    var normalizedURL: URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
}

final class LinkStore {
    static let shared = LinkStore()
    private let key = "egg_tool_links_v1"
    private(set) var links: [LinkItem] = []

    private init() { load() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([LinkItem].self, from: data) else {
            links = []
            return
        }
        links = decoded
        sortLinks()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(links) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(title: String, urlString: String, notes: String) {
        links.insert(LinkItem(title: title, urlString: urlString, notes: notes), at: 0)
        sortLinks(); save()
    }

    func update(_ link: LinkItem, title: String, urlString: String, notes: String) {
        guard let index = links.firstIndex(where: { $0.id == link.id }) else { return }
        links[index].title = title
        links[index].urlString = urlString
        links[index].notes = notes
        links[index].updatedAt = Date()
        sortLinks(); save()
    }

    func delete(_ link: LinkItem) {
        links.removeAll { $0.id == link.id }
        save()
    }

    func togglePinned(_ link: LinkItem) {
        guard let index = links.firstIndex(where: { $0.id == link.id }) else { return }
        links[index].isPinned.toggle()
        links[index].updatedAt = Date()
        sortLinks(); save()
    }

    func filtered(keyword: String) -> [LinkItem] {
        let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return links }
        return links.filter {
            $0.title.localizedCaseInsensitiveContains(text) ||
            $0.urlString.localizedCaseInsensitiveContains(text) ||
            $0.notes.localizedCaseInsensitiveContains(text)
        }
    }

    func replaceAll(_ newLinks: [LinkItem]) {
        links = newLinks
        sortLinks()
        save()
    }

    private func sortLinks() {
        links.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
}
