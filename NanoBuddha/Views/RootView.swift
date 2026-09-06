import SwiftUI

struct RootView: View {
    enum Phase {
        case home
        case sitting(plannedSeconds: Int)
        case done(Session)
    }

    @Environment(Store.self) private var store
    @State private var phase = Phase.home

    var body: some View {
        switch phase {
        case .home:
            HomeView { minutes in
                let seconds = DurationPlanner.realSeconds(nominalMinutes: minutes,
                                                          growthSeconds: store.growthSeconds)
                // Launch argument used by the UI test so a sit finishes in seconds.
                let quickSit = ProcessInfo.processInfo.arguments.contains("-quickSit")
                phase = .sitting(plannedSeconds: quickSit ? 5 : seconds)
            }
        case .sitting(let plannedSeconds):
            SitView(plannedSeconds: plannedSeconds) { session in
                store.record(session)
                phase = .done(session)
            }
        case .done(let session):
            DoneView(session: session) { phase = .home }
        }
    }
}
