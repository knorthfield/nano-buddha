import SwiftUI

@main
struct NanoBuddhaMacApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup(id: "main") {
            MacRootView()
                .environment(store)
                .onAppear {
                    store.didSave = { CloudSync.shared.push() }
                    CloudSync.shared.activate(store: store)
                }
        }
        .defaultSize(width: 900, height: 600)
    }
}
