import UIKit
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
        dismissHealthPrompt(app)
        add(XCTAttachment(screenshot: app.screenshot()))

        XCTAssertTrue(app.staticTexts["Session complete"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 5))
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Total"].waitForExistence(timeout: 5))
        // The Copied label reverts after 2 s, too brief to catch reliably while the starfield
        // animates, so check the pasteboard instead. The simulator shares it with the runner.
        // Reading the string from another app's pasteboard shows a paste-permission alert that
        // blocks the runner, so check only the change count and hasStrings, which do not.
        UIPasteboard.general.items = []
        let changeCount = UIPasteboard.general.changeCount
        app.buttons["CopyWeek"].tap()
        let pasted = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            UIPasteboard.general.changeCount > changeCount && UIPasteboard.general.hasStrings
        }, object: nil)
        XCTAssertEqual(XCTWaiter().wait(for: [pasted], timeout: 5), .completed)
        add(XCTAttachment(screenshot: app.screenshot()))
    }

    func testEndFromTheLiveActivity() {
        let app = XCUIApplication()
        app.launchArguments = ["-quickSit"]
        app.launch()
        app.buttons["Begin"].tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowNotifications = springboard.buttons["Allow"]
        if allowNotifications.waitForExistence(timeout: 3) { allowNotifications.tap() }
        XCTAssertTrue(app.buttons["End"].waitForExistence(timeout: 5))
        sleep(7)

        // Leave the app; the sit carries on and its Live Activity sits in the Dynamic Island.
        XCUIDevice.shared.press(.home)
        sleep(2)
        add(XCTAttachment(screenshot: springboard.screenshot()))
        // Long-press the island to expand it, then tap End there.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).press(forDuration: 1)
        let end = springboard.buttons["End"]
        XCTAssertTrue(end.waitForExistence(timeout: 5))
        add(XCTAttachment(screenshot: springboard.screenshot()))
        end.tap()

        // The intent ran in the app: back in the foreground it is on the Done screen.
        app.activate()
        dismissHealthPrompt(app)
        XCTAssertTrue(app.staticTexts["Session complete"].waitForExistence(timeout: 5))
        XCTAssertFalse(springboard.buttons["End"].exists)
    }

    private func dismissHealthPrompt(_ app: XCUIApplication) {
        // On an iPad without iCloud Health sync the sheet says so instead, with a Not Now button.
        let healthDeny = app.buttons["UIA.Health.DoNotAllow.Button"]
        let healthNotNow = app.buttons["Not Now"]
        let healthSheet = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            healthDeny.exists || healthNotNow.exists
        }, object: nil)
        _ = XCTWaiter().wait(for: [healthSheet], timeout: 15)
        if healthDeny.exists { healthDeny.tap() } else if healthNotNow.exists { healthNotNow.tap() }
        // On a fresh install Health follows up with an "OK" alert that covers the Done screen.
        let healthFollowUp = app.buttons["OK"]
        if healthFollowUp.waitForExistence(timeout: 3) { healthFollowUp.tap() }
    }
}
