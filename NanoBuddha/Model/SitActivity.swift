import ActivityKit
import AppIntents
import Foundation
import UserNotifications

/// The Live Activity for a running sit: no time, only that a sit is on and an End button.
struct SitAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {}
}

enum SitActivity {
    static let endRequested = Notification.Name("SitActivity.endRequested")

    static func start() {
        Task {
            await endAll()
            let content = ActivityContent(state: SitAttributes.ContentState(), staleDate: nil)
            _ = try? Activity<SitAttributes>.request(attributes: SitAttributes(), content: content)
        }
    }

    static func end() {
        Task { await endAll() }
    }

    static func endAll() async {
        for activity in Activity<SitAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

/// The End button on the Live Activity. A LiveActivityIntent runs in the app process (launched in
/// the background if needed), so the post reaches the running SitView. If the app was killed
/// mid-sit nobody hears it: the activity and the pending bell notifications go, the sit is lost.
struct EndSitIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "End sit"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: SitActivity.endRequested, object: nil)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await SitActivity.endAll()
        return .result()
    }
}
