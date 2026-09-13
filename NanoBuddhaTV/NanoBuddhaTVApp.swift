import SwiftUI

@main
struct NanoBuddhaTVApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            TVRootView()
                .environment(store)
                .onAppear {
                    store.didSave = { CloudSync.shared.push() }
                    CloudSync.shared.activate(store: store)
                }
        }
    }
}
