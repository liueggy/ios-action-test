import UIKit
import SwiftUI

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let store = TaskStore()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let content = ContentView()
            .environmentObject(store)

        let hosting = UIHostingController(rootView: content)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hosting
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
