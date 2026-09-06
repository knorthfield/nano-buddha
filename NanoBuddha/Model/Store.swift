import Foundation
import Observation

@Observable
final class Store {
    private(set) var sessions: [Session] = []
    /// The duration the user intends to sit. Grows by 15 s per completed sit.
    var intendedSeconds = 600 { didSet { save() } }

    private struct Snapshot: Codable {
        var sessions: [Session]
        var intendedSeconds: Int?
        // Legacy keys from before intendedSeconds existed; read only.
        var lastNominalMinutes: Int?
        var growthSeconds: Int?
    }

    private let fileURL: URL

    init(fileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("store.json")) {
        self.fileURL = fileURL
        load()
    }

    var totalSeconds: Int { sessions.reduce(0) { $0 + $1.actualSeconds } }

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
        sessions = snapshot.sessions
        intendedSeconds = snapshot.intendedSeconds
            ?? (snapshot.lastNominalMinutes ?? 10) * 60 + (snapshot.growthSeconds ?? 0)
    }

    private func save() {
        let snapshot = Snapshot(sessions: sessions, intendedSeconds: intendedSeconds)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
