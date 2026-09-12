import AVFoundation
import UIKit
import UserNotifications

/// Rings the singing bowl: in the foreground via audio, and when locked via a notification.
enum Bell {
    static let soundFile = "bowl.wav"
    private static let notificationID = "sessionEnd"
    private static var player: AVAudioPlayer?

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { _, _ in }
    }

    static func scheduleNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Nano Buddha"
        content.body = "Your time has passed. Sit on, or end when you are ready."
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundFile))
        let seconds = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [notificationID])
    }

    static func ring() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        guard let url = Bundle.main.url(forResource: soundFile, withExtension: nil) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
