import SwiftUI
import WatchKit

struct WatchSitView: View {
    let plannedSeconds: Int
    let settlingSeconds: Int
    let onFinish: (Session) -> Void

    @State private var sit = Sit()
    @State private var runtime = SitRuntime()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()
            Color.clear
                .frame(width: 80, height: 80)
                .glassEffect(.clear.tint(Color("GlassTint")), in: .circle)
                .accessibilityHidden(true)
            Spacer()
            PrimaryButton(title: "End") { finish() }
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            sit.start(settlingSeconds: settlingSeconds, plannedSeconds: plannedSeconds)
            runtime.start()
        }
        .onReceive(tick) { now in sit.tick(now: now) }
    }

    private func finish() {
        runtime.stop()
        onFinish(sit.finish())
    }
}

/// Keeps the app running with the wrist down: a mindfulness session (Info.plist
/// `WKBackgroundModes`) lasts up to an hour and ends on a crown press. After that the
/// scheduled notifications ring the bells instead, as on a locked phone.
final class SitRuntime: NSObject, WKExtendedRuntimeSessionDelegate {
    private var session: WKExtendedRuntimeSession?

    func start() {
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        self.session = session
    }

    func stop() {
        session?.invalidate()
        session = nil
    }

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {}

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {}

    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        self.session = nil
    }
}
