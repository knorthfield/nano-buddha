import XCTest
@testable import NanoBuddha

final class StoreTests: XCTestCase {
    private var fileURL: URL!

    override func setUp() {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("store-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func session(secondsAgo: Int, completed: Bool = true) -> Session {
        let end = Date.now.addingTimeInterval(-Double(secondsAgo))
        return Session(start: end - 600, end: end, plannedSeconds: 600, completed: completed)
    }

    func testRecordRoundTripsThroughTheFile() {
        let store = Store(fileURL: fileURL)
        store.intendedSeconds = 900
        store.record(session(secondsAgo: 0))

        let reloaded = Store(fileURL: fileURL)
        XCTAssertEqual(reloaded.sessions.count, 1)
        XCTAssertEqual(reloaded.intendedSeconds, 900 + DurationPlanner.growthPerSessionSeconds)
    }

    func testLoadingDoesNotWriteTheFile() throws {
        Store(fileURL: fileURL).record(session(secondsAgo: 0))
        let before = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
        _ = Store(fileURL: fileURL)
        let after = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
        XCTAssertEqual(before, after)
    }

    func testInLastDaysKeepsTheWindowOldestFirst() {
        let day = 24 * 60 * 60
        let sessions = [session(secondsAgo: day), session(secondsAgo: 6 * day), session(secondsAgo: 8 * day)]
        let week = sessions.inLast(days: 7)
        XCTAssertEqual(week.map(\.start), [sessions[1].start, sessions[0].start])
    }
}
