import SwiftUI

struct RootView: View {
    enum Phase {
        case home
        case sitting(plannedSeconds: Int, settlingSeconds: Int)
        case done(Session)
    }

    @Environment(Store.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var phase = Phase.home

    var body: some View {
        Group {
            switch phase {
            case .home:
                HomeView(onStart: beginSit)
            case .sitting(let plannedSeconds, let settlingSeconds):
                SitView(plannedSeconds: plannedSeconds, settlingSeconds: settlingSeconds) { session in
                    store.record(session)
                    phase = .done(session)
                }
            case .done(let session):
                DoneView(session: session) { phase = .home }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { beginSitIfRequested() }
        }
        // The Control Centre intent runs in this process when the app is already active.
        .onReceive(NotificationCenter.default.publisher(for: SitRequest.didPost)) { _ in
            beginSitIfRequested()
        }
    }

    private func beginSit() {
        Bell.requestNotificationPermission()
        let plan = DurationPlanner.plan(intendedSeconds: store.intendedSeconds)
        phase = .sitting(plannedSeconds: plan.plannedSeconds, settlingSeconds: plan.settlingSeconds)
    }

    private func beginSitIfRequested() {
        guard case .home = phase, SitRequest.take() else { return }
        beginSit()
    }
}
