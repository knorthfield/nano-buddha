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

        // The -quickSit bell rings after 5 s; the sit carries on until End is tapped.
        // Ending after the bell counts as complete. Done screen then asks for Health access.
        let end = app.buttons["End"]
        XCTAssertTrue(end.waitForExistence(timeout: 5))
        sleep(7)
        end.tap()
        let healthDeny = app.buttons["UIA.Health.DoNotAllow.Button"]
        if healthDeny.waitForExistence(timeout: 15) { healthDeny.tap() }
        // On a fresh install Health follows up with an "OK" alert that covers the Done screen.
        let healthFollowUp = app.buttons["OK"]
        if healthFollowUp.waitForExistence(timeout: 3) { healthFollowUp.tap() }
        add(XCTAttachment(screenshot: app.screenshot()))

        XCTAssertTrue(app.staticTexts["Session complete"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 5))
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Total"].waitForExistence(timeout: 5))
        add(XCTAttachment(screenshot: app.screenshot()))
    }
}
