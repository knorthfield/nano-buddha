import XCTest
@testable import NanoBuddha

final class DurationPlannerTests: XCTestCase {
    func testRealSecondsAddsGrowthAndJitter() {
        XCTAssertEqual(DurationPlanner.realSeconds(nominalMinutes: 10, growthSeconds: 30, jitter: -20), 610)
    }

    func testRandomJitterStaysWithinOneMinute() {
        for _ in 0..<200 {
            let seconds = DurationPlanner.realSeconds(nominalMinutes: 10, growthSeconds: 0)
            XCTAssert((540...660).contains(seconds), "\(seconds) out of range")
        }
    }

    func testStoreGrowsOnlyOnCompletedSessions() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).json")
        let store = Store(fileURL: url)
        let now = Date()
        store.record(Session(start: now, end: now + 600, plannedSeconds: 600, completed: true))
        store.record(Session(start: now, end: now + 60, plannedSeconds: 600, completed: false))
        XCTAssertEqual(store.growthSeconds, DurationPlanner.growthPerSessionSeconds)
        XCTAssertEqual(Store(fileURL: url).sessions.count, 2)
    }
}
