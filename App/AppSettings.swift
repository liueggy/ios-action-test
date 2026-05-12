import Foundation
import UIKit

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AccentStyle: String, CaseIterable {
    case blue
    case cyan
    case purple
    case green

    var displayName: String {
        switch self {
        case .blue: return "蓝"
        case .cyan: return "青"
        case .purple: return "紫"
        case .green: return "绿"
        }
    }

    var tintColor: UIColor {
        switch self {
        case .blue: return .systemBlue
        case .cyan: return .systemTeal
        case .purple: return .systemPurple
        case .green: return .systemGreen
        }
    }
}

enum AppMode: String, CaseIterable {
    case `default`
    case study
    case work
    case life

    var displayName: String {
        switch self {
        case .default: return "默认"
        case .study: return "学习"
        case .work: return "工作"
        case .life: return "生活"
        }
    }

    var descriptionText: String {
        switch self {
        case .default:
            return "平衡型模式，适合日常待办管理与轻量记录。"
        case .study:
            return "突出截止时间与任务节奏，适合课程、复习与作业安排。"
        case .work:
            return "强调效率与优先级，适合项目推进、会议和协作事务。"
        case .life:
            return "偏向生活记录与提醒，适合买菜、出行、健康与家庭事务。"
        }
    }
}

extension Notification.Name {
    static let appSettingsDidChange = Notification.Name("AppSettingsDidChangeNotification")
}

final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let appearanceMode = "glass_tasks_appearance_mode"
        static let accentStyle = "glass_tasks_accent_style"
        static let appMode = "glass_tasks_app_mode"
        static let quickPhone = "glass_tasks_quick_phone"
        static let quickEmail = "glass_tasks_quick_email"
        static let quickWebsite = "glass_tasks_quick_website"
        static let quickMapQuery = "glass_tasks_quick_map_query"
        static let quickMessage = "glass_tasks_quick_message"
    }

    private(set) var appearanceMode: AppearanceMode
    private(set) var accentStyle: AccentStyle
    private(set) var appMode: AppMode
    private(set) var quickPhone: String
    private(set) var quickEmail: String
    private(set) var quickWebsite: String
    private(set) var quickMapQuery: String
    private(set) var quickMessage: String

    private init() {
        appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "") ?? .system
        accentStyle = AccentStyle(rawValue: defaults.string(forKey: Keys.accentStyle) ?? "") ?? .cyan
        appMode = AppMode(rawValue: defaults.string(forKey: Keys.appMode) ?? "") ?? .default
        quickPhone = defaults.string(forKey: Keys.quickPhone) ?? "10086"
        quickEmail = defaults.string(forKey: Keys.quickEmail) ?? "example@example.com"
        quickWebsite = defaults.string(forKey: Keys.quickWebsite) ?? "https://www.apple.com.cn"
        quickMapQuery = defaults.string(forKey: Keys.quickMapQuery) ?? "成都理工大学"
        quickMessage = defaults.string(forKey: Keys.quickMessage) ?? "你好，我正在使用玻璃待办，需要和你确认一件事情。"
    }

    func updateAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        defaults.set(mode.rawValue, forKey: Keys.appearanceMode)
        notifyAndApply()
    }

    func updateAccentStyle(_ style: AccentStyle) {
        accentStyle = style
        defaults.set(style.rawValue, forKey: Keys.accentStyle)
        notifyAndApply()
    }

    func updateAppMode(_ mode: AppMode) {
        appMode = mode
        defaults.set(mode.rawValue, forKey: Keys.appMode)
        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
    }

    func updateQuickPhone(_ value: String) {
        quickPhone = value
        defaults.set(value, forKey: Keys.quickPhone)
        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
    }

    func updateQuickEmail(_ value: String) {
        quickEmail = value
        defaults.set(value, forKey: Keys.quickEmail)
        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
    }

    func updateQuickWebsite(_ value: String) {
        quickWebsite = value
        defaults.set(value, forKey: Keys.quickWebsite)
        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
    }

    func updateQuickMapQuery(_ value: String) {
        quickMapQuery = value
        defaults.set(value, forKey: Keys.quickMapQuery)
        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
    }

    func updateQuickMessage(_ value: String) {
        quickMessage = value
        defaults.set(value, forKey: Keys.quickMessage)
        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
    }

    func resetPersonalization() {
        updateQuickPhone("10086")
        updateQuickEmail("example@example.com")
        updateQuickWebsite("https://www.apple.com.cn")
        updateQuickMapQuery("成都理工大学")
        updateQuickMessage("你好，我正在使用玻璃待办，需要和你确认一件事情。")
    }

    func applyAppearance() {
        let style = appearanceMode.interfaceStyle
        let tint = accentStyle.tintColor

        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        windows.forEach { window in
            window.overrideUserInterfaceStyle = style
            window.tintColor = tint
        }
    }

    private func notifyAndApply() {
        DispatchQueue.main.async {
            self.applyAppearance()
            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
        }
    }
}
