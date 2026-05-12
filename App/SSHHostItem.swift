import Foundation

struct SSHHostItem: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), name: String, host: String, port: Int = 22, username: String, notes: String = "", createdAt: Date = Date(), updatedAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }

    var sshCommand: String {
        let userPart = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\(username)@"
        return "ssh -p \(port) \(userPart)\(host)"
    }

    var scpUploadTemplate: String {
        let userPart = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\(username)@"
        return "scp -P \(port) ./local-file \(userPart)\(host):~/"
    }

    var scpDownloadTemplate: String {
        let userPart = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\(username)@"
        return "scp -P \(port) \(userPart)\(host):~/remote-file ./"
    }

    var sshURL: URL? {
        var components = URLComponents()
        components.scheme = "ssh"
        components.host = host
        components.port = port
        if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components.user = username
        }
        return components.url
    }
}

final class SSHHostStore {
    static let shared = SSHHostStore()
    private let key = "egg_tool_ssh_hosts_v1"
    private(set) var hosts: [SSHHostItem] = []

    private init() { load() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([SSHHostItem].self, from: data) else {
            hosts = []
            return
        }
        hosts = decoded
        sortHosts()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(hosts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(name: String, host: String, port: Int, username: String, notes: String) {
        hosts.insert(SSHHostItem(name: name, host: host, port: port, username: username, notes: notes), at: 0)
        sortHosts(); save()
    }

    func update(_ item: SSHHostItem, name: String, host: String, port: Int, username: String, notes: String) {
        guard let index = hosts.firstIndex(where: { $0.id == item.id }) else { return }
        hosts[index].name = name
        hosts[index].host = host
        hosts[index].port = port
        hosts[index].username = username
        hosts[index].notes = notes
        hosts[index].updatedAt = Date()
        sortHosts(); save()
    }

    func delete(_ item: SSHHostItem) {
        hosts.removeAll { $0.id == item.id }
        save()
    }

    func togglePinned(_ item: SSHHostItem) {
        guard let index = hosts.firstIndex(where: { $0.id == item.id }) else { return }
        hosts[index].isPinned.toggle()
        hosts[index].updatedAt = Date()
        sortHosts(); save()
    }

    func filtered(keyword: String) -> [SSHHostItem] {
        let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return hosts }
        return hosts.filter {
            $0.name.localizedCaseInsensitiveContains(text) ||
            $0.host.localizedCaseInsensitiveContains(text) ||
            $0.username.localizedCaseInsensitiveContains(text) ||
            $0.notes.localizedCaseInsensitiveContains(text)
        }
    }

    private func sortHosts() {
        hosts.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
}
