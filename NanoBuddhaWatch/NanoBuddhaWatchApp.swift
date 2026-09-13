import SwiftUI

@main
struct NanoBuddhaWatchApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(store)
                .onAppear {
                    store.didSave = { Sync.shared.push(); CloudSync.shared.push() }
                    Sync.shared.activate(store: store)
                    CloudSync.shared.activate(store: store)
                }
        }
    }
}
