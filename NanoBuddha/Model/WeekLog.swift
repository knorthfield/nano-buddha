import Foundation

/// Formats the last seven days of sits as markdown for pasting into a practice thread.
enum WeekLog {
    static func markdown(sessions: [Session], now: Date = .now, calendar: Calendar = .current) -> String {
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        let week = sessions.filter { $0.start >= weekStart && $0.start < now }.sorted { $0.start < $1.start }
        let totalSeconds = week.reduce(0) { $0 + $1.actualSeconds }
        let totalMinutes = Int((Double(totalSeconds) / 60).rounded())

        let dayFormatter = formatter("d MMM yyyy", calendar: calendar)
        let sitFormatter = formatter("EEE d MMM, HH:mm", calendar: calendar)
        var lines = ["**Sits, \(dayFormatter.string(from: weekStart))–\(dayFormatter.string(from: now))** — \(week.count) sits, \(totalMinutes) min"]
        if !week.isEmpty {
            lines.append("")
            for session in week {
                var line = "- \(sitFormatter.string(from: session.start)) — \(session.actualMinutes) min"
                if !session.completed { line += " (ended early)" }
                lines.append(line)
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func formatter(_ format: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter
    }
}
