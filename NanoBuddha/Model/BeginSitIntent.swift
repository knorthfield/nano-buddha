import AppIntents
import Foundation

/// A request to begin a sit, left by the Control Centre button for the app to pick up.
/// A file in the app group rather than UserDefaults: group defaults lose writes on the simulator.
enum SitRequest {
    static let didPost = Notification.Name("SitRequest.didPost")

    static var defaultFileURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Store.appGroup)
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("sitRequest")
    }

    static func post(now: Date = .now, fileURL: URL = defaultFileURL) {
        try? String(now.timeIntervalSince1970).write(to: fileURL, atomically: true, encoding: .utf8)
        NotificationCenter.default.post(name: didPost, object: nil)
    }

    /// True once per request, and only while the request is fresh.
    static func take(now: Date = .now, maxAge: TimeInterval = 60, fileURL: URL = defaultFileURL) -> Bool {
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return false }
        try? FileManager.default.removeItem(at: fileURL)
        guard let stamp = TimeInterval(text) else { return false }
        return now.timeIntervalSince1970 - stamp < maxAge
    }
}

struct BeginSitIntent: AppIntent {
    static let title: LocalizedStringResource = "Begin sit"
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SitRequest.post()
        return .result()
    }
}
