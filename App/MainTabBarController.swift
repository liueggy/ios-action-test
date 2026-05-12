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
        let tasks = UINavigationController(rootViewController: TasksViewController(style: .insetGrouped))
        tasks.tabBarItem = UITabBarItem(title: "待办", image: UIImage(systemName: "checklist"), selectedImage: UIImage(systemName: "checklist"))

        let actions = UINavigationController(rootViewController: QuickActionsViewController(style: .insetGrouped))
        actions.tabBarItem = UITabBarItem(title: "快捷", image: UIImage(systemName: "bolt.circle"), selectedImage: UIImage(systemName: "bolt.circle.fill"))

        let settings = UINavigationController(rootViewController: SettingsViewController(style: .insetGrouped))
        settings.tabBarItem = UITabBarItem(title: "设置", image: UIImage(systemName: "slider.horizontal.3"), selectedImage: UIImage(systemName: "slider.horizontal.3"))

        viewControllers = [tasks, actions, settings]
        selectedIndex = 0
        tabBar.isTranslucent = true
    }

    @objc private func handleSettingsChange() {
        AppSettings.shared.applyAppearance()
    }
}
