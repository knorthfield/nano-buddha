import Foundation
import Observation

@Observable
final class Store {
    private(set) var sessions: [Session] = []
    private(set) var growthSeconds = 0
    var lastNominalMinutes = 10 { didSet { save() } }

    private struct Snapshot: Codable {
        var sessions: [Session]
        var growthSeconds: Int
        var lastNominalMinutes: Int
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
            growthSeconds += DurationPlanner.growthPerSessionSeconds
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        sessions = snapshot.sessions
        growthSeconds = snapshot.growthSeconds
        lastNominalMinutes = snapshot.lastNominalMinutes
    }

    private func save() {
        let snapshot = Snapshot(sessions: sessions, growthSeconds: growthSeconds,
                                lastNominalMinutes: lastNominalMinutes)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
