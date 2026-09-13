import SwiftUI

/// Home, sit, done. Every app compiles this with its own HomeView and SitView under those names.
struct RootView: View {
    enum Phase {
        case home
        case sitting(plannedSeconds: Int, settlingSeconds: Int)
        case done(Session)
    }

    @Environment(Store.self) private var store
    @State private var phase = Phase.home
    #if os(iOS) || os(watchOS)
    @Environment(\.scenePhase) private var scenePhase
    #endif

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
        #if os(iOS) || os(watchOS)
        // A Siri, Shortcuts or Control Centre "Begin sit" leaves a request; a cold launch sees
        // it on activation, a warm one through the notification.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { beginSitIfRequested() }
        }
        .onReceive(NotificationCenter.default.publisher(for: SitRequest.didPost)) { _ in
            beginSitIfRequested()
        }
        #endif
    }

    private func beginSit() {
        Bell.requestNotificationPermission()
        let plan = DurationPlanner.plan(intendedSeconds: store.intendedSeconds)
        phase = .sitting(plannedSeconds: plan.plannedSeconds, settlingSeconds: plan.settlingSeconds)
    }

    #if os(iOS) || os(watchOS)
    private func beginSitIfRequested() {
        if case .sitting = phase { return }  // A running sit is not interrupted.
        guard SitRequest.take() else { return }
        beginSit()
    }
    #endif
}
