import Foundation

/// Keeps the stores of every device on one iCloud account the same. Every save puts the whole
/// snapshot in the iCloud key-value store; the other devices merge it when it arrives.
final class CloudSync {
    static let shared = CloudSync()
    /// The key-value store holds 1 MB in total. The merge keeps older sits on the receiver anyway.
    static let maxSessions = 4000
    private static let key = "snapshot"
    private var store: Store?

    func activate(store: Store) {
        self.store = store
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in self?.merge() }
        NSUbiquitousKeyValueStore.default.synchronize()
        merge()
        push()
    }

    func push() {
        guard let store else { return }
        var snapshot = store.snapshot
        snapshot.sessions = Array(snapshot.sessions.suffix(Self.maxSessions))
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: Self.key)
    }

    private func merge() {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: Self.key),
              let snapshot = try? JSONDecoder().decode(Store.Snapshot.self, from: data) else { return }
        store?.merge(snapshot)
    }
}
