import SwiftUI

@main
struct NanoBuddhaApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .onAppear {
                    store.didSave = { Sync.shared.push(); CloudSync.shared.push() }
                    Sync.shared.activate(store: store)
                    CloudSync.shared.activate(store: store)
                }
        }
    }
}
