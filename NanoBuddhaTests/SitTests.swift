import XCTest
@testable import NanoBuddha

final class SitTests: XCTestCase {
    func testSitStartsAfterTheSettlingSilence() {
        let sit = Sit()
        let begin = Date()
        sit.start(settlingSeconds: 30, plannedSeconds: 600, now: begin)
        XCTAssertEqual(sit.sitStart, begin + 30)
        XCTAssertEqual(sit.endDate, begin + 630)
    }

    func testEndAfterTheTargetCountsAsCompleted() {
        let sit = Sit()
        let begin = Date()
        sit.start(settlingSeconds: 30, plannedSeconds: 600, now: begin)
        let session = sit.finish(now: begin + 700)
        XCTAssertTrue(session.completed)
        XCTAssertEqual(session.start, begin + 30)
        XCTAssertEqual(session.end, begin + 700)
        XCTAssertEqual(session.plannedSeconds, 600)
    }

    func testEndBeforeTheTargetIsNotCompleted() {
        let sit = Sit()
        let begin = Date()
        sit.start(settlingSeconds: 30, plannedSeconds: 600, now: begin)
        XCTAssertFalse(sit.finish(now: begin + 300).completed)
    }

    func testEndDuringTheSettlingSilenceHasNoLength() {
        let sit = Sit()
        let begin = Date()
        sit.start(settlingSeconds: 30, plannedSeconds: 600, now: begin)
        let session = sit.finish(now: begin + 10)
        XCTAssertEqual(session.actualSeconds, 0)
        XCTAssertFalse(session.completed)
    }
}
