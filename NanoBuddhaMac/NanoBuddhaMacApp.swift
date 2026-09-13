import SwiftUI

@main
struct NanoBuddhaMacApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup(id: "main") {
            RootView()
                .environment(store)
                .onAppear {
                    store.didSave = { CloudSync.shared.push() }
                    CloudSync.shared.activate(store: store)
                }
        }
        .defaultSize(width: 900, height: 600)
        // One window: a second one would run a second sit on the same bells.
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
