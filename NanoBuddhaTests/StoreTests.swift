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

final class StoreMergeTests: XCTestCase {
    private func session(secondsAgo: Int) -> Session {
        let end = Date.now.addingTimeInterval(-Double(secondsAgo))
        return Session(start: end - 600, end: end, plannedSeconds: 600, completed: true)
    }

    private func temporaryStore() -> Store {
        Store(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).json"))
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
