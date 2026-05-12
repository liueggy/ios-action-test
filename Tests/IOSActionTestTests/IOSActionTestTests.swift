import XCTest
@testable import IOSActionTest

final class IOSActionTestTests: XCTestCase {
    func testGreeting() {
        let app = IOSActionTest()
        XCTAssertTrue(app.greeting().contains("GitHub Actions"))
    }
}
