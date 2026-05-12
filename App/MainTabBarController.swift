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

        let tasks = UINavigationController(rootViewController: TasksViewController(style: .insetGrouped))
        tasks.navigationBar.prefersLargeTitles = true
        tasks.navigationBar.standardAppearance = navAppearance
        tasks.navigationBar.scrollEdgeAppearance = navAppearance
        tasks.tabBarItem = UITabBarItem(title: "待办", image: UIImage(systemName: "checklist"), selectedImage: UIImage(systemName: "checklist"))

        let actions = UINavigationController(rootViewController: QuickActionsViewController(style: .insetGrouped))
        actions.navigationBar.prefersLargeTitles = true
        actions.navigationBar.standardAppearance = navAppearance
        actions.navigationBar.scrollEdgeAppearance = navAppearance
        actions.tabBarItem = UITabBarItem(title: "快捷", image: UIImage(systemName: "bolt.circle"), selectedImage: UIImage(systemName: "bolt.circle.fill"))

        let settings = UINavigationController(rootViewController: SettingsViewController(style: .insetGrouped))
        settings.navigationBar.prefersLargeTitles = true
        settings.navigationBar.standardAppearance = navAppearance
        settings.navigationBar.scrollEdgeAppearance = navAppearance
        settings.tabBarItem = UITabBarItem(title: "设置", image: UIImage(systemName: "slider.horizontal.3"), selectedImage: UIImage(systemName: "slider.horizontal.3"))

        viewControllers = [tasks, actions, settings]
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
