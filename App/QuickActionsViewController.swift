import UIKit

final class QuickActionsViewController: UITableViewController {
    private let settings = AppSettings.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "快捷操作"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(reloadContent))
        tableView.backgroundColor = .systemGroupedBackground
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: .appSettingsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 4
        default: return 3
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "联系与沟通"
        case 1: return "系统与常用应用"
        default: return "内容处理"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "当前模式：\(settings.appMode.displayName)。你可以在设置中修改常用电话、网页、地图关键词和短信模板。"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .disclosureIndicator

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            configure(cell, title: "拨打常用电话", subtitle: settings.quickPhone, image: "phone.fill")
        case (0, 1):
            configure(cell, title: "发送短信", subtitle: settings.quickMessage, image: "message.fill")
        case (0, 2):
            configure(cell, title: "发送邮件", subtitle: settings.quickEmail, image: "envelope.fill")
        case (1, 0):
            configure(cell, title: "打开常用网页", subtitle: settings.quickWebsite, image: "safari.fill")
        case (1, 1):
            configure(cell, title: "地图搜索", subtitle: settings.quickMapQuery, image: "map.fill")
        case (1, 2):
            configure(cell, title: "打开日历", subtitle: "跳转到系统日历应用", image: "calendar")
        case (1, 3):
            configure(cell, title: "打开本 App 设置", subtitle: "进入系统设置里的权限页面", image: "gearshape.2.fill")
        case (2, 0):
            configure(cell, title: "分享待办摘要", subtitle: "通过系统分享面板导出任务概况", image: "square.and.arrow.up")
        case (2, 1):
            configure(cell, title: "复制今日摘要", subtitle: "复制到剪贴板，便于粘贴到其他应用", image: "doc.on.doc")
        case (2, 2):
            configure(cell, title: "刷新当前配置", subtitle: "重新读取模式与个性化设置", image: "arrow.clockwise")
        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            callPhone()
        case (0, 1):
            sendSMS()
        case (0, 2):
            sendMail()
        case (1, 0):
            openWebsite()
        case (1, 1):
            openMaps()
        case (1, 2):
            openCalendar()
        case (1, 3):
            openAppSettings()
        case (2, 0):
            shareSummary()
        case (2, 1):
            copySummary()
        case (2, 2):
            reloadContent()
        default:
            break
        }
    }

    @objc private func reloadContent() {
        tableView.reloadData()
    }

    private func configure(_ cell: UITableViewCell, title: String, subtitle: String, image: String) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.lineBreakMode = .byTruncatingMiddle
        cell.imageView?.image = UIImage(systemName: image)
        cell.imageView?.tintColor = AppSettings.shared.accentStyle.tintColor
    }

    private func callPhone() {
        let phone = settings.quickPhone.filter { "0123456789+".contains($0) }
        openURLString("tel://\(phone)", failureMessage: "无法拨打该号码，请在设置中检查常用电话。")
    }

    private func sendSMS() {
        let body = settings.quickMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        openURLString("sms:?body=\(body)", failureMessage: "无法打开短信，请检查设备是否支持。")
    }

    private func sendMail() {
        let email = settings.quickEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subject = "来自玻璃待办".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = settings.quickMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        openURLString("mailto:\(email)?subject=\(subject)&body=\(body)", failureMessage: "无法打开邮件，请检查邮箱地址格式。")
    }

    private func openWebsite() {
        let value = settings.quickWebsite.hasPrefix("http://") || settings.quickWebsite.hasPrefix("https://") ? settings.quickWebsite : "https://\(settings.quickWebsite)"
        openURLString(value, failureMessage: "无法打开该网页，请在设置中检查网址。")
    }

    private func openMaps() {
        let query = settings.quickMapQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        openURLString("http://maps.apple.com/?q=\(query)", failureMessage: "无法打开地图搜索。")
    }

    private func openCalendar() {
        openURLString("calshow://", failureMessage: "无法打开系统日历。")
    }

    private func openAppSettings() {
        openURLString(UIApplication.openSettingsURLString, failureMessage: "无法打开设置页面。")
    }

    private func shareSummary() {
        let text = TaskStore.shared.summaryText(modeName: settings.appMode.displayName)
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = tableView
        controller.popoverPresentationController?.sourceRect = CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: 1, height: 1)
        present(controller, animated: true)
    }

    private func copySummary() {
        UIPasteboard.general.string = TaskStore.shared.summaryText(modeName: settings.appMode.displayName)
        let alert = UIAlertController(title: "已复制", message: "今日摘要已经复制到剪贴板。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    private func openURLString(_ string: String, failureMessage: String) {
        guard let url = URL(string: string) else {
            showError(message: failureMessage)
            return
        }

        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            if !success {
                DispatchQueue.main.async {
                    self?.showError(message: failureMessage)
                }
            }
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "操作失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}
