import Foundation
import Observation

/// The timing of one sit: the settling silence, the opening bell, the target bell and End.
/// Shared by the iPhone and the watch; each view owns its screen and the 1 s tick.
@Observable
final class Sit {
    private(set) var sitStart = Date()
    private(set) var endDate = Date()
    private var plannedSeconds = 0
    private var openingRung = false
    private var targetRung = false

    func start(settlingSeconds: Int, plannedSeconds: Int, now: Date = .now) {
        self.plannedSeconds = plannedSeconds
        sitStart = now.addingTimeInterval(TimeInterval(settlingSeconds))
        endDate = sitStart.addingTimeInterval(TimeInterval(plannedSeconds))
        Bell.scheduleNotification(for: .opening, at: sitStart)
        Bell.scheduleNotification(for: .target, at: endDate)
    }

    /// The opening bell marks the start of the sit after the settling silence; the target bell
    /// marks the target. The sit carries on until the user taps End.
    func tick(now: Date = .now) {
        if now >= sitStart && !openingRung {
            openingRung = true
            ring(.opening, due: sitStart, now: now)
        }
        if now >= endDate && !targetRung {
            targetRung = true
            ring(.target, due: endDate, now: now)
        }
    }

    func finish(now: Date = .now) -> Session {
        Bell.cancelNotifications()
        Bell.shared.stop()
        // An End during the settling silence records a sit of no length, not a negative one.
        return Session(start: min(sitStart, now), end: now, plannedSeconds: plannedSeconds,
                       completed: now >= endDate)
    }

    private func ring(_ moment: Bell.Moment, due: Date, now: Date) {
        Bell.cancelNotification(for: moment)
        // The timer does not tick while the phone is locked. If the moment passed more than
        // a couple of seconds ago the notification already rang, so do not ring twice.
        if now.timeIntervalSince(due) < 2 { Bell.shared.ring() }
    }
}
