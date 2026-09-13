import SwiftUI

struct MacSitView: View {
    let plannedSeconds: Int
    let settlingSeconds: Int
    let onFinish: (Session) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sit = Sit()
    @State private var breathing = false
    /// Holds the Mac awake so the bells ring; the display may still sleep.
    @State private var awake: NSObjectProtocol?
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Starfield()
            Color.clear
                .frame(width: 160, height: 160)
                .glassEffect(.clear.tint(Color("GlassTint")), in: .circle)
                .scaleEffect(breathing ? 1.08 : 1)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: breathing)
                .accessibilityHidden(true)
            VStack {
                Spacer()
                PrimaryButton(title: "End") { finish() }
                    .keyboardShortcut(.cancelAction)  // Escape ends the sit.
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            sit.start(settlingSeconds: settlingSeconds, plannedSeconds: plannedSeconds)
            awake = ProcessInfo.processInfo.beginActivity(options: .idleSystemSleepDisabled, reason: "Sitting")
            breathing = !reduceMotion
        }
        .onReceive(tick) { now in sit.tick(now: now) }
    }

    private func finish() {
        if let awake { ProcessInfo.processInfo.endActivity(awake) }
        awake = nil
        onFinish(sit.finish())
    }
}
