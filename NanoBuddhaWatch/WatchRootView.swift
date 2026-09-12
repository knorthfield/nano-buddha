import SwiftUI

struct WatchRootView: View {
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
                WatchHomeView(onStart: beginSit)
            case .sitting(let plannedSeconds, let settlingSeconds):
                WatchSitView(plannedSeconds: plannedSeconds, settlingSeconds: settlingSeconds) { session in
                    store.record(session)
                    phase = .done(session)
                }
            case .done(let session):
                WatchDoneView(session: session) { phase = .home }
            }
        }
        // A Siri or Shortcuts "Begin sit" leaves a request; a cold launch sees it on activation,
        // a warm one through the notification.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { beginSitIfRequested() }
        }
        .onReceive(NotificationCenter.default.publisher(for: SitRequest.didPost)) { _ in
            beginSitIfRequested()
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

    private func beginSitIfRequested() {
        guard case .home = phase, SitRequest.take() else { return }
        beginSit()
    }
}
