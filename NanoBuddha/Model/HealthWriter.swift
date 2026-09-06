import HealthKit

enum HealthWriter {
    private static let healthStore = HKHealthStore()
    private static let mindfulType = HKCategoryType(.mindfulSession)

    /// Saves the session as Mindful Minutes. Returns a short status line for the UI.
    static func save(_ session: Session) async -> String {
        guard HKHealthStore.isHealthDataAvailable() else { return "Health not available on this device" }
        do {
            try await healthStore.requestAuthorization(toShare: [mindfulType], read: [])
            guard healthStore.authorizationStatus(for: mindfulType) == .sharingAuthorized else {
                return "Health access not granted"
            }
            let sample = HKCategorySample(type: mindfulType,
                                          value: HKCategoryValue.notApplicable.rawValue,
                                          start: session.start, end: session.end)
            try await healthStore.save(sample)
            return "Saved to Health as Mindful Minutes"
        } catch {
            return "Could not save to Health"
        }
    }
}
