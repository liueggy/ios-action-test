import Foundation

public struct IOSActionTest {
    public let name: String

    public init(name: String = "GitHub Actions iOS Build") {
        self.name = name
    }

    public func greeting() -> String {
        "Hello from \(name)!"
    }

    public static func platformSummary() -> String {
        #if os(iOS)
        return "Compiled for iOS"
        #elseif os(macOS)
        return "Compiled for macOS"
        #else
        return "Compiled for another Apple platform"
        #endif
    }
}
