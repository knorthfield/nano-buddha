import AVFoundation
import UIKit
import UserNotifications

/// Rings the singing bowl: in the foreground via audio, and when locked via a notification.
final class Bell: NSObject, AVAudioPlayerDelegate {
    static let shared = Bell()
    static let soundFile = "bowl.wav"
    private var player: AVAudioPlayer?

    /// The two moments a bell marks. Each has its own notification so both can be pending at once.
    enum Moment: CaseIterable {
        case opening, target

        fileprivate var notificationID: String {
            switch self {
            case .opening: "sitStart"
            case .target: "sessionEnd"
            }
        }

        fileprivate var notificationBody: String {
            switch self {
            case .opening: "Your sit begins."
            case .target: "Your time has passed. Sit on, or end when you are ready."
            }
        }
    }
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { _, _ in }
    }

    static func scheduleNotification(for moment: Moment, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Nano Buddha"
        content.body = moment.notificationBody
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundFile))
        let seconds = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: moment.notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelNotification(for moment: Moment) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [moment.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [moment.notificationID])
    }

    static func cancelNotifications() {
        Moment.allCases.forEach(cancelNotification)
    }

    func ring() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        guard let url = Bundle.main.url(forResource: Self.soundFile, withExtension: nil) else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        activateSessionAndPlay()
    }

    /// Cuts a ringing bowl and hands audio back to other apps.
    func stop() {
        player?.stop()
        player = nil
        deactivateSession()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        deactivateSession()
    }

    /// A phone call or Siri stops the bowl. When the interruption ends, ring it again from the
    /// start: a bowl resumed mid-decay sounds wrong, and the point is that the bell is heard.
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: typeValue) == .ended,
              let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
              AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume),
              let player, !player.isPlaying
        else { return }
        player.currentTime = 0
        activateSessionAndPlay()
    }

    private func activateSessionAndPlay() {
        let session = AVAudioSession.sharedInstance()
        // Playback ignores the silent switch; ducking lowers other audio instead of stopping it.
        try? session.setCategory(.playback, options: [.duckOthers])
        try? session.setActive(true)
        player?.play()
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
