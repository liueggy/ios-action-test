import UIKit

final class SettingsViewController: UITableViewController {
    private let settings = AppSettings.shared

    private lazy var appearanceControl: UISegmentedControl = {
        let control = UISegmentedControl(items: AppearanceMode.allCases.map { $0.displayName })
        control.selectedSegmentIndex = AppearanceMode.allCases.firstIndex(of: settings.appearanceMode) ?? 0
        control.addTarget(self, action: #selector(appearanceChanged(_:)), for: .valueChanged)
        return control
    }()

    private lazy var accentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: AccentStyle.allCases.map { $0.displayName })
        control.selectedSegmentIndex = AccentStyle.allCases.firstIndex(of: settings.accentStyle) ?? 0
        control.addTarget(self, action: #selector(accentChanged(_:)), for: .valueChanged)
        return control
    }()

    private lazy var modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: AppMode.allCases.map { $0.displayName })
        control.selectedSegmentIndex = AppMode.allCases.firstIndex(of: settings.appMode) ?? 0
        control.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置"
        navigationItem.largeTitleDisplayMode = .always
        tableView.backgroundColor = .systemGroupedBackground
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: .appSettingsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 4 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 2
        case 2: return 5
        default: return 2
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "界面外观"
        case 1: return "应用模式"
        case 2: return "个性化快捷操作"
        default: return "其他"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "优先使用系统控件与半透明材质，以便在新的 iOS 设计语言下自然呈现液态玻璃风格。"
        case 2:
            return "这些内容会被“快捷”页直接调用，例如拨号、短信、地图搜索和网页打开。"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let style: UITableViewCell.CellStyle = (indexPath.section == 1 && indexPath.row == 1) || indexPath.section >= 2 ? .subtitle : .value1
        let cell = UITableViewCell(style: style, reuseIdentifier: nil)
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .none
        cell.selectionStyle = .default

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "外观模式"
            cell.accessoryView = appearanceControl
            cell.selectionStyle = .none
        case (0, 1):
            cell.textLabel?.text = "强调色"
            cell.accessoryView = accentControl
            cell.selectionStyle = .none
        case (1, 0):
            cell.textLabel?.text = "场景模式"
            cell.accessoryView = modeControl
            cell.selectionStyle = .none
        case (1, 1):
            cell.textLabel?.text = "当前模式说明"
            cell.detailTextLabel?.text = settings.appMode.descriptionText
            cell.detailTextLabel?.numberOfLines = 0
            cell.selectionStyle = .none
        case (2, 0):
            cell.textLabel?.text = "常用电话"
            cell.detailTextLabel?.text = settings.quickPhone
            cell.accessoryType = .disclosureIndicator
        case (2, 1):
            cell.textLabel?.text = "常用邮箱"
            cell.detailTextLabel?.text = settings.quickEmail
            cell.accessoryType = .disclosureIndicator
        case (2, 2):
            cell.textLabel?.text = "常用网址"
            cell.detailTextLabel?.text = settings.quickWebsite
            cell.detailTextLabel?.lineBreakMode = .byTruncatingMiddle
            cell.accessoryType = .disclosureIndicator
        case (2, 3):
            cell.textLabel?.text = "地图关键词"
            cell.detailTextLabel?.text = settings.quickMapQuery
            cell.accessoryType = .disclosureIndicator
        case (2, 4):
            cell.textLabel?.text = "短信模板"
            cell.detailTextLabel?.text = settings.quickMessage
            cell.detailTextLabel?.numberOfLines = 2
            cell.accessoryType = .disclosureIndicator
        case (3, 0):
            cell.textLabel?.text = "功能说明"
            cell.detailTextLabel?.text = "待办、日历、快捷调用与摘要分享"
            cell.accessoryType = .disclosureIndicator
        case (3, 1):
            cell.textLabel?.text = "恢复默认个性化设置"
            cell.detailTextLabel?.text = "保留任务数据，仅重置快捷操作配置"
        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch (indexPath.section, indexPath.row) {
        case (2, 0):
            pushEditor(title: "常用电话", current: settings.quickPhone, placeholder: "例如 10086 或 13800138000") {
                self.settings.updateQuickPhone($0)
            }
        case (2, 1):
            pushEditor(title: "常用邮箱", current: settings.quickEmail, placeholder: "例如 name@example.com") {
                self.settings.updateQuickEmail($0)
            }
        case (2, 2):
            pushEditor(title: "常用网址", current: settings.quickWebsite, placeholder: "例如 https://www.apple.com.cn") {
                self.settings.updateQuickWebsite($0)
            }
        case (2, 3):
            pushEditor(title: "地图关键词", current: settings.quickMapQuery, placeholder: "例如 成都理工大学") {
                self.settings.updateQuickMapQuery($0)
            }
        case (2, 4):
            pushEditor(title: "短信模板", current: settings.quickMessage, placeholder: "输入默认短信内容") {
                self.settings.updateQuickMessage($0)
            }
        case (3, 0):
            showInfoAlert()
        case (3, 1):
            settings.resetPersonalization()
            reloadContent()
        default:
            break
        }
    }

    @objc private func appearanceChanged(_ sender: UISegmentedControl) {
        settings.updateAppearanceMode(AppearanceMode.allCases[sender.selectedSegmentIndex])
    }

    @objc private func accentChanged(_ sender: UISegmentedControl) {
        settings.updateAccentStyle(AccentStyle.allCases[sender.selectedSegmentIndex])
    }

    @objc private func modeChanged(_ sender: UISegmentedControl) {
        settings.updateAppMode(AppMode.allCases[sender.selectedSegmentIndex])
        reloadContent()
    }

    @objc private func reloadContent() {
        appearanceControl.selectedSegmentIndex = AppearanceMode.allCases.firstIndex(of: settings.appearanceMode) ?? 0
        accentControl.selectedSegmentIndex = AccentStyle.allCases.firstIndex(of: settings.accentStyle) ?? 0
        modeControl.selectedSegmentIndex = AppMode.allCases.firstIndex(of: settings.appMode) ?? 0
        tableView.reloadData()
    }

    private func pushEditor(title: String, current: String, placeholder: String, onSave: @escaping (String) -> Void) {
        let controller = TextEditViewController(titleText: title, value: current, placeholder: placeholder, onSave: onSave)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func showInfoAlert() {
        let message = "玻璃待办采用中文界面，支持任务管理、日历写入、个性化快捷调用、外观模式切换和待办摘要分享。界面尽量使用系统原生导航、标签栏和分组控件，以便在较新的 iOS 设计语言下自然获得液态玻璃观感。"
        let alert = UIAlertController(title: "功能说明", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}
