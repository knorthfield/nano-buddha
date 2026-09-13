import XCTest
@testable import NanoBuddha

final class StoreTests: XCTestCase {
    private var fileURLs: [URL] = []

    override func tearDown() {
        fileURLs.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    private func temporaryURL() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("store-\(UUID().uuidString).json")
        fileURLs.append(url)
        return url
    }

    private func temporaryStore() -> Store { Store(fileURL: temporaryURL()) }

    private func session(secondsAgo: Int, completed: Bool = true) -> Session {
        let end = Date.now.addingTimeInterval(-Double(secondsAgo))
        return Session(start: end - 600, end: end, plannedSeconds: 600, completed: completed)
    }

    func testRecordRoundTripsThroughTheFile() {
        let url = temporaryURL()
        let store = Store(fileURL: url)
        store.intendedSeconds = 900
        var saves = 0
        store.didSave = { saves += 1 }
        store.record(session(secondsAgo: 0))
        XCTAssertEqual(saves, 1)

        let reloaded = Store(fileURL: url)
        XCTAssertEqual(reloaded.sessions.count, 1)
        XCTAssertEqual(reloaded.intendedSeconds, 900 + DurationPlanner.growthPerSessionSeconds)
    }

    func testStoreGrowsOnlyOnCompletedSessions() {
        let store = temporaryStore()
        store.record(session(secondsAgo: 0))
        store.record(session(secondsAgo: 0, completed: false))
        XCTAssertEqual(store.intendedSeconds, 600 + DurationPlanner.growthPerSessionSeconds)
    }

    func testLoadingDoesNotWriteTheFile() throws {
        let url = temporaryURL()
        Store(fileURL: url).record(session(secondsAgo: 0))
        let before = try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
        _ = Store(fileURL: url)
        let after = try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
        XCTAssertEqual(before, after)
    }

    func testLoadsLegacySnapshot() throws {
        let url = temporaryURL()
        let legacy = #"{"sessions":[],"lastNominalMinutes":10,"growthSeconds":45}"#
        try legacy.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertEqual(Store(fileURL: url).intendedSeconds, 645)
    }

    func testNudgeFloorsAtOneMinute() {
        let store = temporaryStore()
        store.nudge(by: -600)
        XCTAssertEqual(store.intendedSeconds, 60)
        store.nudge(by: 60)
        XCTAssertEqual(store.intendedSeconds, 120)
    }

    func testIntendedTimeTextShowsOddSeconds() {
        let store = temporaryStore()
        store.intendedSeconds = 600
        XCTAssertEqual(store.intendedTimeText, "10 min")
        store.intendedSeconds = 615
        XCTAssertEqual(store.intendedTimeText, "10 min 15 s")
    }

    func testMinutesRoundToNearestLikeHealth() {
        let now = Date()
        let store = temporaryStore()
        store.record(Session(start: now, end: now + 280, plannedSeconds: 300, completed: true))
        store.record(Session(start: now, end: now + 290, plannedSeconds: 300, completed: true))
        XCTAssertEqual(store.sessions[0].actualMinutes, 5)
        XCTAssertEqual(Session(start: now, end: now + 269, plannedSeconds: 300, completed: true).actualMinutes, 4)
        XCTAssertEqual(store.totalMinutes, 10)
    }

    func testInLastDaysKeepsTheWindowOldestFirst() {
        let day = 24 * 60 * 60
        let sessions = [session(secondsAgo: day), session(secondsAgo: 6 * day), session(secondsAgo: 8 * day)]
        let week = sessions.inLast(days: 7)
        XCTAssertEqual(week.map(\.start), [sessions[1].start, sessions[0].start])
    }

    func testMergeAddsUnseenSitsOldestFirst() {
        let mine = temporaryStore()
        let theirs = temporaryStore()
        let older = session(secondsAgo: 7200)
        let newer = session(secondsAgo: 60)
        mine.record(newer)
        theirs.record(older)
        theirs.record(newer)

        XCTAssertTrue(mine.merge(theirs.snapshot))
        XCTAssertEqual(mine.sessions.map(\.id), [older.id, newer.id])
        XCTAssertFalse(mine.merge(theirs.snapshot), "nothing new the second time")
    }

    func testMergeTakesTheNewerIntendedDuration() {
        let mine = temporaryStore()
        let theirs = temporaryStore()
        mine.intendedSeconds = 900
        theirs.intendedSeconds = 1200

        XCTAssertTrue(mine.merge(theirs.snapshot))
        XCTAssertEqual(mine.intendedSeconds, 1200)
        XCTAssertFalse(theirs.merge(mine.snapshot), "the older value does not win")
        XCTAssertEqual(theirs.intendedSeconds, 1200)
    }

    func testMergeSavesAndTellsTheListener() {
        let mine = temporaryStore()
        let theirs = temporaryStore()
        theirs.record(session(secondsAgo: 0))
        var saves = 0
        mine.didSave = { saves += 1 }

        mine.merge(theirs.snapshot)
        XCTAssertEqual(saves, 1)
        mine.merge(theirs.snapshot)
        XCTAssertEqual(saves, 1, "an unchanged merge does not save")
    }
}
