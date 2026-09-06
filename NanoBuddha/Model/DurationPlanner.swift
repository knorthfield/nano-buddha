import Foundation

enum DurationPlanner {
    static let jitterSeconds = 60
    static let growthPerSessionSeconds = 15

    /// The real number of seconds to sit. The user never sees this.
    static func realSeconds(nominalMinutes: Int, growthSeconds: Int,
                            jitter: Int = Int.random(in: -jitterSeconds...jitterSeconds)) -> Int {
        max(60, nominalMinutes * 60 + growthSeconds + jitter)
    }
}
