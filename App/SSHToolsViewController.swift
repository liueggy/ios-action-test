import UIKit
import Network

final class SSHToolsViewController: UITableViewController, UISearchResultsUpdating {
    private let store = SSHHostStore.shared
    private let searchController = UISearchController(searchResultsController: nil)
    private var keyword = ""
    private var connection: NWConnection?

    private var visibleHosts: [SSHHostItem] { store.filtered(keyword: keyword) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SSH"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addHost))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(EggCardCell.self, forCellReuseIdentifier: EggCardCell.reuseIdentifier)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索主机、用户或备注"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        keyword = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { max(visibleHosts.count, 1) }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Egg Tool 当前提供 SSH 主机管理、端口连通性测试、命令生成和 ssh:// 调起外部客户端。不保存密码或私钥。"
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { visibleHosts.isEmpty ? UITableView.automaticDimension : 92 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !visibleHosts.isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var content = UIListContentConfiguration.subtitleCell()
            content.text = keyword.isEmpty ? "还没有 SSH 主机" : "没有匹配的主机"
            content.secondaryText = keyword.isEmpty ? "点击右上角 + 添加服务器、开发板或 NAS" : "换个关键词试试"
            content.image = UIImage(systemName: "terminal")
            content.imageProperties.tintColor = AppSettings.shared.accentStyle.tintColor
            cell.contentConfiguration = content
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.selectionStyle = .none
            return cell
        }

        let item = visibleHosts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: EggCardCell.reuseIdentifier, for: indexPath) as! EggCardCell
        cell.configure(
            title: item.name,
            subtitle: "\(item.username.isEmpty ? "user" : item.username)@\(item.host):\(item.port)" + (item.notes.isEmpty ? "" : " · \(item.notes)"),
            icon: item.isPinned ? "pin.fill" : "terminal.fill",
            tint: item.isPinned ? .systemOrange : AppSettings.shared.accentStyle.tintColor,
            trailing: item.isPinned ? "置顶" : "SSH",
            showsChevron: true
        )
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !visibleHosts.isEmpty else { return }
        showActions(for: visibleHosts[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !visibleHosts.isEmpty else { return nil }
        let item = visibleHosts[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            self?.store.delete(item); self?.tableView.reloadData(); done(true)
        }
        let pin = UIContextualAction(style: .normal, title: item.isPinned ? "取消置顶" : "置顶") { [weak self] _, _, done in
            self?.store.togglePinned(item); self?.tableView.reloadData(); done(true)
        }
        pin.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [delete, pin])
    }

    @objc private func addHost() { openEditor(item: nil) }

    private func showActions(for item: SSHHostItem) {
        let alert = UIAlertController(title: item.name, message: "\(item.host):\(item.port)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "测试端口连通性", style: .default) { [weak self] _ in self?.testConnection(item) })
        alert.addAction(UIAlertAction(title: "打开 ssh://", style: .default) { [weak self] _ in self?.openSSHURL(item) })
        alert.addAction(UIAlertAction(title: "复制 SSH 命令", style: .default) { _ in UIPasteboard.general.string = item.sshCommand })
        alert.addAction(UIAlertAction(title: "复制 SCP 上传模板", style: .default) { _ in UIPasteboard.general.string = item.scpUploadTemplate })
        alert.addAction(UIAlertAction(title: "复制 SCP 下载模板", style: .default) { _ in UIPasteboard.general.string = item.scpDownloadTemplate })
        alert.addAction(UIAlertAction(title: "编辑", style: .default) { [weak self] _ in self?.openEditor(item: item) })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.sourceView = tableView
        present(alert, animated: true)
    }

    private func openSSHURL(_ item: SSHHostItem) {
        guard let url = item.sshURL else { showAlert(title: "无法打开", message: "SSH URL 格式无效。") ; return }
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            if !success {
                DispatchQueue.main.async {
                    self?.showAlert(title: "没有可用客户端", message: "系统没有能处理 ssh:// 的应用。你可以复制 SSH 命令到 Termius、Blink、Prompt、a-Shell 或 iSH 中使用。")
                }
            }
        }
    }

    private func testConnection(_ item: SSHHostItem) {
        connection?.cancel()
        guard let port = NWEndpoint.Port(rawValue: UInt16(item.port)) else {
            showAlert(title: "端口无效", message: "请输入 1-65535 的端口。")
            return
        }
        let start = Date()
        let connection = NWConnection(host: NWEndpoint.Host(item.host), port: port, using: .tcp)
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                let ms = Int(Date().timeIntervalSince(start) * 1000)
                connection.cancel()
                DispatchQueue.main.async { self?.showAlert(title: "连接成功", message: "\(item.host):\(item.port) 可连接\n耗时：\(ms) ms") }
            case .failed(let error):
                connection.cancel()
                DispatchQueue.main.async { self?.showAlert(title: "连接失败", message: error.localizedDescription) }
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self, weak connection] in
            guard let connection, connection === self?.connection else { return }
            connection.cancel()
            self?.showAlert(title: "连接超时", message: "8 秒内无法连接 \(item.host):\(item.port)。")
        }
    }

    private func openEditor(item: SSHHostItem?) {
        let controller = SSHHostEditorViewController(item: item) { [weak self] name, host, port, username, notes in
            guard let self else { return }
            if let item { self.store.update(item, name: name, host: host, port: port, username: username, notes: notes) }
            else { self.store.add(name: name, host: host, port: port, username: username, notes: notes) }
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

final class SSHHostEditorViewController: UITableViewController {
    private let nameField = UITextField()
    private let hostField = UITextField()
    private let portField = UITextField()
    private let usernameField = UITextField()
    private let notesView = UITextView()
    private let item: SSHHostItem?
    private let onSave: (String, String, Int, String, String) -> Void

    init(item: SSHHostItem?, onSave: @escaping (String, String, Int, String, String) -> Void) {
        self.item = item
        self.onSave = onSave
        super.init(style: .insetGrouped)
        title = item == nil ? "新增 SSH" : "编辑 SSH"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        tableView.backgroundColor = .systemGroupedBackground
        setupFields()
    }

    private func setupFields() {
        nameField.placeholder = "名称，例如 Firefly / NAS / VPS"
        nameField.text = item?.name
        hostField.placeholder = "主机，例如 192.168.1.10 或 example.com"
        hostField.text = item?.host
        hostField.autocapitalizationType = .none
        hostField.autocorrectionType = .no
        portField.placeholder = "端口，默认 22"
        portField.text = item == nil ? "22" : "\(item!.port)"
        portField.keyboardType = .numberPad
        usernameField.placeholder = "用户名，例如 root"
        usernameField.text = item?.username
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        notesView.text = item?.notes
        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.backgroundColor = .clear
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 4 : 1 }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { section == 0 ? "连接信息" : "备注" }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? { section == 0 ? "Egg Tool 不保存密码或私钥。请在外部 SSH 客户端中管理凭据。" : nil }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { indexPath.section == 1 ? 150 : 52 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.selectionStyle = .none
        if indexPath.section == 0 {
            let fields = [nameField, hostField, portField, usernameField]
            embed(fields[indexPath.row], in: cell)
        } else {
            notesView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(notesView)
            NSLayoutConstraint.activate([
                notesView.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                notesView.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                notesView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
                notesView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6)
            ])
        }
        return cell
    }

    private func embed(_ field: UITextField, in cell: UITableViewCell) {
        field.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])
    }

    @objc private func save() {
        let host = (hostField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let username = (usernameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = notesView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = Int((portField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 22
        var name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { showAlert("请填写主机地址。") ; return }
        guard (1...65535).contains(port) else { showAlert("端口必须在 1-65535 之间。") ; return }
        if name.isEmpty { name = host }
        onSave(name, host, port, username, notes)
        navigationController?.popViewController(animated: true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
