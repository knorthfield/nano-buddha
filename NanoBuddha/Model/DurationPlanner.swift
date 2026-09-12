import Foundation

enum DurationPlanner {
    static let jitterSeconds = 60
    static let growthPerSessionSeconds = 15
    /// Silence between Begin and the opening bell, so the user can put the phone down first.
    static let settlingSeconds = 30

    /// The real number of seconds to sit. The jitter is hidden from the user.
    static func realSeconds(intendedSeconds: Int,
                            jitter: Int = Int.random(in: -jitterSeconds...jitterSeconds)) -> Int {
        max(60, intendedSeconds + jitter)
    }
}
