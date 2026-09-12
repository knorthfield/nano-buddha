import SwiftUI

@main
struct NanoBuddhaTVApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            TVRootView()
                .environment(store)
        }
    }
}
