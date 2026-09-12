import Foundation

struct Session: Codable, Identifiable {
    var id = UUID()
    var start: Date
    var end: Date
    var plannedSeconds: Int
    var completed: Bool

    var actualSeconds: Int { Int(end.timeIntervalSince(start)) }
    var actualMinutes: Int { Int((Double(actualSeconds) / 60).rounded()) }
}

extension Array where Element == Session {
    /// Sits that started in the last `days` days, oldest first.
    func inLast(days: Int, now: Date = .now, calendar: Calendar = .current) -> [Session] {
        let windowStart = calendar.date(byAdding: .day, value: -days, to: now)!
        return filter { $0.start >= windowStart && $0.start < now }.sorted { $0.start < $1.start }
    }
}
