import SwiftUI

struct RootView: View {
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
            HomeView {
                let seconds = DurationPlanner.realSeconds(intendedSeconds: store.intendedSeconds)
                // Launch argument used by the UI test so a sit finishes in seconds.
                let quickSit = ProcessInfo.processInfo.arguments.contains("-quickSit")
                phase = .sitting(plannedSeconds: quickSit ? 5 : seconds,
                                 settlingSeconds: quickSit ? 0 : DurationPlanner.settlingSeconds)
            }
        case .sitting(let plannedSeconds, let settlingSeconds):
            SitView(plannedSeconds: plannedSeconds, settlingSeconds: settlingSeconds) { session in
                store.record(session)
                phase = .done(session)
            }
        case .done(let session):
            DoneView(session: session) { phase = .home }
        }
    }
}
