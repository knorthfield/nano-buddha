import Foundation

struct Session: Codable, Identifiable {
    var id = UUID()
    var start: Date
    var end: Date
    var plannedSeconds: Int
    var completed: Bool

    var actualSeconds: Int { Int(end.timeIntervalSince(start)) }
}
