import XCTest

final class SitFlowUITests: XCTestCase {
    func testQuickSitReachesCompletionAndHistory() {
        let app = XCUIApplication()
        app.launchArguments = ["-quickSit"]
        app.launch()

        app.buttons["Begin"].tap()

        // Notification permission alert lives in SpringBoard.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowNotifications = springboard.buttons["Allow"]
        if allowNotifications.waitForExistence(timeout: 3) { allowNotifications.tap() }

        // The -quickSit sit lasts 5 s; Done screen then asks for Health access.
        let healthDeny = app.buttons["UIA.Health.DoNotAllow.Button"]
        if healthDeny.waitForExistence(timeout: 15) { healthDeny.tap() }
        add(XCTAttachment(screenshot: app.screenshot()))

        XCTAssertTrue(app.staticTexts["Session complete"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 5))
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Hidden growth"].waitForExistence(timeout: 5))
        add(XCTAttachment(screenshot: app.screenshot()))
    }
}
