import XCTest
@testable import NanoBuddha

final class DurationPlannerTests: XCTestCase {
    func testRealSecondsAddsJitter() {
        XCTAssertEqual(DurationPlanner.realSeconds(intendedSeconds: 630, jitter: -20), 610)
    }

    func testRandomJitterStaysWithinOneMinute() {
        for _ in 0..<200 {
            let seconds = DurationPlanner.realSeconds(intendedSeconds: 600)
            XCTAssert((540...660).contains(seconds), "\(seconds) out of range")
        }
    }

    func testStoreGrowsOnlyOnCompletedSessions() throws {
        let url = temporaryURL()
        let store = Store(fileURL: url)
        let now = Date()
        store.record(Session(start: now, end: now + 600, plannedSeconds: 600, completed: true))
        store.record(Session(start: now, end: now + 60, plannedSeconds: 600, completed: false))
        XCTAssertEqual(store.intendedSeconds, 600 + DurationPlanner.growthPerSessionSeconds)
        let reloaded = Store(fileURL: url)
        XCTAssertEqual(reloaded.sessions.count, 2)
        XCTAssertEqual(reloaded.intendedSeconds, 600 + DurationPlanner.growthPerSessionSeconds)
    }

    func testNudgeFloorsAtOneMinute() {
        let store = Store(fileURL: temporaryURL())
        store.nudge(by: -600)
        XCTAssertEqual(store.intendedSeconds, 60)
        store.nudge(by: 60)
        XCTAssertEqual(store.intendedSeconds, 120)
    }

    func testLoadsLegacySnapshot() throws {
        let url = temporaryURL()
        let legacy = #"{"sessions":[],"lastNominalMinutes":10,"growthSeconds":45}"#
        try legacy.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertEqual(Store(fileURL: url).intendedSeconds, 645)
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).json")
    }
}
