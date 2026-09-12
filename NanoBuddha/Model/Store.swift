import Foundation
import Observation
import WidgetKit

@Observable
final class Store {
    static let appGroup = "group.com.krisnorthfield.NanoBuddha"

    private(set) var sessions: [Session] = []
    /// The duration the user intends to sit. Grows by 15 s per completed sit.
    var intendedSeconds = 600 { didSet { if !isLoading { save() } } }

    private struct Snapshot: Codable {
        var sessions: [Session]
        var intendedSeconds: Int?
        // Legacy keys from before intendedSeconds existed; read only.
        var lastNominalMinutes: Int?
        var growthSeconds: Int?
    }

    private let fileURL: URL
    private var isLoading = false

    /// The store lives in the app group so the widget can read it. The first launch after the
    /// move takes the old file from Documents with it.
    static var defaultFileURL: URL {
        let files = FileManager.default
        let documents = files.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("store.json")
        guard let group = files.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("store.json") else { return documents }
        if !files.fileExists(atPath: group.path), files.fileExists(atPath: documents.path) {
            try? files.moveItem(at: documents, to: group)
        }
        return group
    }

    init(fileURL: URL = Store.defaultFileURL) {
        self.fileURL = fileURL
        load()
    }

    var totalSeconds: Int { sessions.reduce(0) { $0 + $1.actualSeconds } }
    var totalMinutes: Int { Int((Double(totalSeconds) / 60).rounded()) }

    func record(_ session: Session) {
        sessions.append(session)
        if session.completed {
            intendedSeconds += DurationPlanner.growthPerSessionSeconds
        }
        save()
    }

    func nudge(by seconds: Int) {
        intendedSeconds = max(60, intendedSeconds + seconds)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        isLoading = true
        defer { isLoading = false }
        sessions = snapshot.sessions
        intendedSeconds = snapshot.intendedSeconds
            ?? (snapshot.lastNominalMinutes ?? 10) * 60 + (snapshot.growthSeconds ?? 0)
    }

    private func save() {
        let snapshot = Snapshot(sessions: sessions, intendedSeconds: intendedSeconds)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
