import Foundation
import UniformTypeIdentifiers

struct ReaderItem: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var fileName: String
    var originalName: String
    var fileExtension: String
    var importedAt: Date
    var updatedAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), title: String, fileName: String, originalName: String, fileExtension: String, importedAt: Date = Date(), updatedAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.originalName = originalName
        self.fileExtension = fileExtension
        self.importedAt = importedAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }
}

final class ReaderStore {
    static let shared = ReaderStore()

    private let key = "egg_tool_reader_items_v1"
    private(set) var items: [ReaderItem] = []

    private init() {
        createDirectoryIfNeeded()
        load()
    }

    var readerDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("EggReader", isDirectory: true)
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: readerDirectory, withIntermediateDirectories: true)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([ReaderItem].self, from: data) else {
            items = []
            return
        }
        items = decoded.filter { FileManager.default.fileExists(atPath: fileURL(for: $0).path) }
        sortItems()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func fileURL(for item: ReaderItem) -> URL {
        readerDirectory.appendingPathComponent(item.fileName)
    }

    func importFile(from sourceURL: URL) throws {
        createDirectoryIfNeeded()
        let access = sourceURL.startAccessingSecurityScopedResource()
        defer { if access { sourceURL.stopAccessingSecurityScopedResource() } }

        let originalName = sourceURL.lastPathComponent
        let ext = sourceURL.pathExtension.lowercased()
        let baseTitle = sourceURL.deletingPathExtension().lastPathComponent
        let fileName = "\(UUID().uuidString).\(ext.isEmpty ? "file" : ext)"
        let destination = readerDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)

        let item = ReaderItem(title: baseTitle.isEmpty ? originalName : baseTitle, fileName: fileName, originalName: originalName, fileExtension: ext)
        items.insert(item, at: 0)
        sortItems()
        save()
    }

    func delete(_ item: ReaderItem) {
        let url = fileURL(for: item)
        try? FileManager.default.removeItem(at: url)
        items.removeAll { $0.id == item.id }
        save()
    }

    func togglePinned(_ item: ReaderItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        items[index].updatedAt = Date()
        sortItems()
        save()
    }

    func rename(_ item: ReaderItem, title: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].title = title
        items[index].updatedAt = Date()
        sortItems()
        save()
    }

    func filtered(keyword: String) -> [ReaderItem] {
        let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(text) ||
            $0.originalName.localizedCaseInsensitiveContains(text) ||
            $0.fileExtension.localizedCaseInsensitiveContains(text)
        }
    }

    private func sortItems() {
        items.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
}

enum ReaderFileKind {
    case text
    case image
    case quickLook

    static func kind(for ext: String) -> ReaderFileKind {
        let e = ext.lowercased()
        if ["txt", "md", "markdown", "json", "csv", "log", "xml", "html", "htm", "yaml", "yml", "swift", "py", "js", "ts", "css"].contains(e) {
            return .text
        }
        if ["png", "jpg", "jpeg", "gif", "webp", "heic", "heif"].contains(e) {
            return .image
        }
        return .quickLook
    }
}
