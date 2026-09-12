import AppIntents

/// Puts Begin sit in Siri, Spotlight, the Shortcuts app and the Action button.
/// Compiled into the iOS and watch apps only: an AppShortcutsProvider belongs in an app, not an extension.
struct NanoBuddhaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: BeginSitIntent(),
                    phrases: ["Begin a sit in \(.applicationName)",
                              "Start a sit in \(.applicationName)",
                              "Begin \(.applicationName)"],
                    shortTitle: "Begin sit",
                    systemImageName: "figure.mind.and.body")
    }
}
