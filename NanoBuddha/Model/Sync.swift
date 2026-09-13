import Foundation
import WatchConnectivity

/// Keeps the iPhone and the watch stores the same. Every save sends the whole snapshot as the
/// application context; the other side merges it when it next runs.
final class Sync: NSObject, WCSessionDelegate {
    static let shared = Sync()
    /// The context is capped at about 64 KB. The merge keeps older sits on the receiver anyway.
    static let maxSessions = 400
    private var store: Store?

    func activate(store: Store) {
        guard WCSession.isSupported() else { return }
        self.store = store
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func push() {
        guard let store, WCSession.default.activationState == .activated else { return }
        var snapshot = store.snapshot
        snapshot.sessions = Array(snapshot.sessions.suffix(Self.maxSessions))
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? WCSession.default.updateApplicationContext(["snapshot": data])
    }

    private func merge(_ context: [String: Any]) {
        guard let data = context["snapshot"] as? Data,
              let snapshot = try? JSONDecoder().decode(Store.Snapshot.self, from: data) else { return }
        DispatchQueue.main.async { _ = self.store?.merge(snapshot) }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        guard state == .activated else { return }
        merge(session.receivedApplicationContext)
        push()
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        merge(context)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    /// The user switched to another watch; a new activation follows it.
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
