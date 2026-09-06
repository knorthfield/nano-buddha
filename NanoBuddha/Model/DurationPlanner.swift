import Foundation

enum DurationPlanner {
    static let jitterSeconds = 60
    static let growthPerSessionSeconds = 15

    /// The real number of seconds to sit. The jitter is hidden from the user.
    static func realSeconds(intendedSeconds: Int,
                            jitter: Int = Int.random(in: -jitterSeconds...jitterSeconds)) -> Int {
        max(60, intendedSeconds + jitter)
    }
}
