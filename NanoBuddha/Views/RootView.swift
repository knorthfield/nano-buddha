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
                phase = .sitting(plannedSeconds: seconds)
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
