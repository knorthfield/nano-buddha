import XCTest
@testable import NanoBuddha

final class DurationPlannerTests: XCTestCase {
    func testRealSecondsAddsJitter() {
        XCTAssertEqual(DurationPlanner.realSeconds(intendedSeconds: 630, jitter: -20), 610)
    }

    func testRealSecondsFloorsAtOneMinute() {
        XCTAssertEqual(DurationPlanner.realSeconds(intendedSeconds: 60, jitter: -60), 60)
    }

    func testRandomJitterStaysWithinOneMinute() {
        for _ in 0..<200 {
            let seconds = DurationPlanner.realSeconds(intendedSeconds: 600)
            XCTAssert((540...660).contains(seconds), "\(seconds) out of range")
        }
    }

    func testQuickSitPlansFiveSecondsWithNoSettling() {
        let plan = DurationPlanner.plan(intendedSeconds: 600, arguments: ["-quickSit"])
        XCTAssertEqual(plan.plannedSeconds, 5)
        XCTAssertEqual(plan.settlingSeconds, 0)
    }

    func testPlanKeepsSettlingAndJitter() {
        let plan = DurationPlanner.plan(intendedSeconds: 600, arguments: [])
        XCTAssertEqual(plan.settlingSeconds, DurationPlanner.settlingSeconds)
        XCTAssert((540...660).contains(plan.plannedSeconds), "\(plan.plannedSeconds) out of range")
    }
}
