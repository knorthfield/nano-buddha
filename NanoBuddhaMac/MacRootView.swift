import SwiftUI

struct MacRootView: View {
    enum Phase {
        case home
        case sitting(plannedSeconds: Int, settlingSeconds: Int)
        case done(Session)
    }

    @Environment(Store.self) private var store
    @State private var phase = Phase.home

    var body: some View {
        switch phase {
        case .home:
            MacHomeView(onStart: beginSit)
        case .sitting(let plannedSeconds, let settlingSeconds):
            MacSitView(plannedSeconds: plannedSeconds, settlingSeconds: settlingSeconds) { session in
                store.record(session)
                phase = .done(session)
            }
        case .done(let session):
            MacDoneView(session: session) { phase = .home }
        }
    }

    private func beginSit() {
        Bell.requestNotificationPermission()
        let seconds = DurationPlanner.realSeconds(intendedSeconds: store.intendedSeconds)
        // Launch argument so a sit finishes in seconds while testing.
        let quickSit = ProcessInfo.processInfo.arguments.contains("-quickSit")
        phase = .sitting(plannedSeconds: quickSit ? 5 : seconds,
                         settlingSeconds: quickSit ? 0 : DurationPlanner.settlingSeconds)
    }
}
