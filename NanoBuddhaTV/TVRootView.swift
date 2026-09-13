import SwiftUI

struct TVRootView: View {
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
            TVHomeView(onStart: beginSit)
        case .sitting(let plannedSeconds, let settlingSeconds):
            TVSitView(plannedSeconds: plannedSeconds, settlingSeconds: settlingSeconds) { session in
                store.record(session)
                phase = .done(session)
            }
        case .done(let session):
            TVDoneView(session: session) { phase = .home }
        }
    }

    private func beginSit() {
        let plan = DurationPlanner.plan(intendedSeconds: store.intendedSeconds)
        phase = .sitting(plannedSeconds: plan.plannedSeconds, settlingSeconds: plan.settlingSeconds)
    }
}
