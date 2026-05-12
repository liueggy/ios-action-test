import UIKit

final class ToolboxViewController: UICollectionViewController {
    struct ToolItem: Hashable {
        let title: String
        let subtitle: String
        let icon: String
        let tint: UIColor
        let action: Action

        enum Action: Hashable {
            case phone
            case sms
            case mail
            case website
            case maps
            case calendar
            case appSettings
            case shareSummary
            case copySummary
            case comingSoon(String)
        }
    }

    private let settings = AppSettings.shared
    private var tools: [ToolItem] { makeTools() }

    init() {
        super.init(collectionViewLayout: Self.makeLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "工具箱"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(reloadContent))
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(ToolboxCell.self, forCellWithReuseIdentifier: ToolboxCell.reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: .appSettingsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tools.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ToolboxCell.reuseIdentifier, for: indexPath) as! ToolboxCell
        cell.configure(with: tools[indexPath.item])
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tool = tools[indexPath.item]
        collectionView.deselectItem(at: indexPath, animated: true)
        perform(tool.action)
    }

    private static func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(118))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 7, bottom: 7, trailing: 7)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(118))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 28, trailing: 14)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func makeTools() -> [ToolItem] {
        let accent = AppSettings.shared.accentStyle.tintColor
        return [
            ToolItem(title: "拨号", subtitle: settings.quickPhone, icon: "phone.fill", tint: .systemGreen, action: .phone),
            ToolItem(title: "短信", subtitle: "发送模板消息", icon: "message.fill", tint: .systemBlue, action: .sms),
            ToolItem(title: "邮件", subtitle: settings.quickEmail, icon: "envelope.fill", tint: .systemIndigo, action: .mail),
            ToolItem(title: "网页", subtitle: settings.quickWebsite, icon: "safari.fill", tint: accent, action: .website),
            ToolItem(title: "地图", subtitle: settings.quickMapQuery, icon: "map.fill", tint: .systemOrange, action: .maps),
            ToolItem(title: "日历", subtitle: "打开系统日历", icon: "calendar", tint: .systemRed, action: .calendar),
            ToolItem(title: "复制摘要", subtitle: "待办概览到剪贴板", icon: "doc.on.doc.fill", tint: .systemPurple, action: .copySummary),
            ToolItem(title: "分享摘要", subtitle: "通过系统分享面板", icon: "square.and.arrow.up.fill", tint: accent, action: .shareSummary),
            ToolItem(title: "文本工具", subtitle: "字数 / JSON / Base64", icon: "textformat.abc", tint: .systemTeal, action: .comingSoon("文本工具")),
            ToolItem(title: "OCR", subtitle: "图片识别文字", icon: "viewfinder", tint: .systemPink, action: .comingSoon("OCR")),
            ToolItem(title: "二维码", subtitle: "生成与识别", icon: "qrcode.viewfinder", tint: .systemGray, action: .comingSoon("二维码")),
            ToolItem(title: "App 设置", subtitle: "权限和系统设置", icon: "gearshape.2.fill", tint: .secondaryLabel, action: .appSettings)
        ]
    }

    private func perform(_ action: ToolItem.Action) {
        switch action {
        case .phone: callPhone()
        case .sms: sendSMS()
        case .mail: sendMail()
        case .website: openWebsite()
        case .maps: openMaps()
        case .calendar: openURLString("calshow://", failureMessage: "无法打开系统日历。")
        case .appSettings: openURLString(UIApplication.openSettingsURLString, failureMessage: "无法打开设置页面。")
        case .shareSummary: shareSummary()
        case .copySummary: copySummary()
        case .comingSoon(let title): showComingSoon(title)
        }
    }

    @objc private func reloadContent() {
        collectionView.reloadData()
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
        let subject = "来自 Egg Tool".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
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

    private func shareSummary() {
        let text = TaskStore.shared.summaryText(modeName: settings.appMode.displayName)
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = collectionView
        controller.popoverPresentationController?.sourceRect = CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: 1, height: 1)
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

    private func showComingSoon(_ title: String) {
        let alert = UIAlertController(title: title, message: "这个工具入口已经预留，会在后续版本中启用。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "操作失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}

private final class ToolboxCell: UICollectionViewCell {
    static let reuseIdentifier = "ToolboxCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 20
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byTruncatingMiddle

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3)
        ])
    }

    func configure(with item: ToolboxViewController.ToolItem) {
        iconView.image = UIImage(systemName: item.icon)
        iconView.tintColor = item.tint
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}
