import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabs()
        AppSettings.shared.applyAppearance()
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsChange), name: .appSettingsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureTabs() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()

        let today = UINavigationController(rootViewController: DashboardViewController(style: .insetGrouped))
        today.navigationBar.prefersLargeTitles = true
        today.navigationBar.standardAppearance = navAppearance
        today.navigationBar.scrollEdgeAppearance = navAppearance
        today.tabBarItem = UITabBarItem(title: "今日", image: UIImage(systemName: "sparkles.rectangle.stack"), selectedImage: UIImage(systemName: "sparkles.rectangle.stack.fill"))

        let tasks = UINavigationController(rootViewController: TasksViewController(style: .insetGrouped))
        tasks.navigationBar.prefersLargeTitles = true
        tasks.navigationBar.standardAppearance = navAppearance
        tasks.navigationBar.scrollEdgeAppearance = navAppearance
        tasks.tabBarItem = UITabBarItem(title: "任务", image: UIImage(systemName: "checklist"), selectedImage: UIImage(systemName: "checklist"))

        let toolbox = UINavigationController(rootViewController: ToolboxViewController())
        toolbox.navigationBar.prefersLargeTitles = true
        toolbox.navigationBar.standardAppearance = navAppearance
        toolbox.navigationBar.scrollEdgeAppearance = navAppearance
        toolbox.tabBarItem = UITabBarItem(title: "工具", image: UIImage(systemName: "square.grid.2x2"), selectedImage: UIImage(systemName: "square.grid.2x2.fill"))

        let reader = UINavigationController(rootViewController: ReaderViewController(style: .insetGrouped))
        reader.navigationBar.prefersLargeTitles = true
        reader.navigationBar.standardAppearance = navAppearance
        reader.navigationBar.scrollEdgeAppearance = navAppearance
        reader.tabBarItem = UITabBarItem(title: "阅读", image: UIImage(systemName: "books.vertical"), selectedImage: UIImage(systemName: "books.vertical.fill"))

        let notes = UINavigationController(rootViewController: NotesViewController(style: .insetGrouped))
        notes.navigationBar.prefersLargeTitles = true
        notes.navigationBar.standardAppearance = navAppearance
        notes.navigationBar.scrollEdgeAppearance = navAppearance
        notes.tabBarItem = UITabBarItem(title: "记录", image: UIImage(systemName: "note.text"), selectedImage: UIImage(systemName: "note.text"))

        let settings = UINavigationController(rootViewController: SettingsViewController(style: .insetGrouped))
        settings.navigationBar.prefersLargeTitles = true
        settings.navigationBar.standardAppearance = navAppearance
        settings.navigationBar.scrollEdgeAppearance = navAppearance
        settings.tabBarItem = UITabBarItem(title: "设置", image: UIImage(systemName: "slider.horizontal.3"), selectedImage: UIImage(systemName: "slider.horizontal.3"))

        viewControllers = [today, tasks, toolbox, reader, notes, settings]
        selectedIndex = 0

        // Use UITabBarAppearance to ensure correct background in both light and dark mode
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
    }

    @objc private func handleSettingsChange() {
        AppSettings.shared.applyAppearance()
    }
}
