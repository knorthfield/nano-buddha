import XCTest
@testable import NanoBuddha

final class WeekLogTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }
    // 2026-09-12 08:00 Europe/London
    private let now = Date(timeIntervalSince1970: 1_789_196_400)

    private func session(daysAgo: Int, seconds: Int, completed: Bool = true) -> Session {
        let start = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return Session(start: start, end: start + TimeInterval(seconds), plannedSeconds: seconds, completed: completed)
    }

    func testFormatsTheLastSevenDaysOldestFirst() {
        let sessions = [
            session(daysAgo: 1, seconds: 22 * 60 + 20),
            session(daysAgo: 6, seconds: 19 * 60, completed: false),
            session(daysAgo: 8, seconds: 30 * 60),
        ]
        let expected = """
        **Sits, 5 Sep 2026–12 Sep 2026** — 2 sits, 41 min

        - Sun 6 Sep, 08:00 — 19 min
        - Fri 11 Sep, 08:00 — 22 min
        """
        XCTAssertEqual(WeekLog.markdown(sessions: sessions, now: now, calendar: calendar), expected)
    }

    func testEmptyWeekIsHeaderOnly() {
        XCTAssertEqual(
            WeekLog.markdown(sessions: [], now: now, calendar: calendar),
            "**Sits, 5 Sep 2026–12 Sep 2026** — 0 sits, 0 min"
        )
    }
}
