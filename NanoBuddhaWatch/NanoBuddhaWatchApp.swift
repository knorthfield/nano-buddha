import SwiftUI

@main
struct NanoBuddhaWatchApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(store)
                .onAppear { Sync.shared.activate(store: store) }
        }
    }
}
