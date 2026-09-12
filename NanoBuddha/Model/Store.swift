import Foundation
import Observation
#if canImport(WidgetKit)
import WidgetKit
#endif

@Observable
final class Store {
    static let appGroup = "group.com.krisnorthfield.NanoBuddha"

    private(set) var sessions: [Session] = []
    /// The duration the user intends to sit. Grows by 15 s per completed sit.
    var intendedSeconds = 600 {
        didSet {
            guard !isRestoring else { return }
            intendedUpdatedAt = .now
            save()
        }
    }
    /// When the intended duration last changed on this device; the newer device wins a merge.
    private var intendedUpdatedAt: Date?
    /// Called after every save, so the other device can be told.
    var didSave: (() -> Void)?

    struct Snapshot: Codable {
        var sessions: [Session]
        var intendedSeconds: Int?
        var intendedUpdatedAt: Date?
        // Legacy keys from before intendedSeconds existed; read only.
        var lastNominalMinutes: Int?
        var growthSeconds: Int?
    }

    private let fileURL: URL
    private var isRestoring = false

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

    var intendedTimeText: String {
        var text = "\(intendedSeconds / 60) min"
        if intendedSeconds % 60 != 0 { text += " \(intendedSeconds % 60) s" }
        return text
    }

    var snapshot: Snapshot {
        Snapshot(sessions: sessions, intendedSeconds: intendedSeconds, intendedUpdatedAt: intendedUpdatedAt)
    }

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

    /// Takes in what the other device knows: its sits this device has not seen, and its
    /// intended duration if it changed more recently. Returns false when nothing was new, so
    /// the two devices do not answer each other forever.
    @discardableResult
    func merge(_ other: Snapshot) -> Bool {
        var changed = false
        let known = Set(sessions.map(\.id))
        let unseen = other.sessions.filter { !known.contains($0.id) }
        if !unseen.isEmpty {
            sessions = (sessions + unseen).sorted { $0.start < $1.start }
            changed = true
        }
        if let seconds = other.intendedSeconds, seconds != intendedSeconds,
           let theirs = other.intendedUpdatedAt, theirs > (intendedUpdatedAt ?? .distantPast) {
            isRestoring = true
            intendedSeconds = seconds
            intendedUpdatedAt = theirs
            isRestoring = false
            changed = true
        }
        if changed { save() }
        return changed
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        isRestoring = true
        defer { isRestoring = false }
        sessions = snapshot.sessions
        intendedSeconds = snapshot.intendedSeconds
            ?? (snapshot.lastNominalMinutes ?? 10) * 60 + (snapshot.growthSeconds ?? 0)
        intendedUpdatedAt = snapshot.intendedUpdatedAt
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        didSave?()
    }
}
