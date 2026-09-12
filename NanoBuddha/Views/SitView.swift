import SwiftUI

struct SitView: View {
    let plannedSeconds: Int
    let settlingSeconds: Int
    let onFinish: (Session) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sitStart = Date()
    @State private var endDate = Date()
    @State private var breathing = false
    @State private var highlightTurning = false
    @State private var openingRung = false
    @State private var targetRung = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Starfield()
            Color.clear
                .frame(width: 160, height: 160)
                .glassEffect(.clear.tint(Color("GlassTint")), in: .circle)
                .overlay {
                    ZStack {
                        Circle().strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.8), .clear, .clear, .white.opacity(0.25)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5)
                        Ellipse()
                            .fill(.white.opacity(0.35))
                            .frame(width: 70, height: 36)
                            .rotationEffect(.degrees(-35))
                            .blur(radius: 10)
                            .offset(x: -30, y: -32)
                    }
                    .rotationEffect(.degrees(highlightTurning ? 360 : 0))
                    .animation(.linear(duration: 90).repeatForever(autoreverses: false), value: highlightTurning)
                }
                .scaleEffect(breathing ? 1.08 : 1)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: breathing)
                .accessibilityHidden(true)
            VStack {
                Spacer()
                PrimaryButton(title: "End") { finish() }
                    .padding(.bottom, 40)
            }
        }
        .statusBarHidden()
        .onAppear {
            sitStart = Date().addingTimeInterval(TimeInterval(settlingSeconds))
            endDate = sitStart.addingTimeInterval(TimeInterval(plannedSeconds))
            Bell.scheduleNotification(for: .opening, at: sitStart)
            Bell.scheduleNotification(for: .target, at: endDate)
            UIApplication.shared.isIdleTimerDisabled = true
            breathing = !reduceMotion
            highlightTurning = !reduceMotion
        }
        .onReceive(tick) { now in
            if now >= sitStart && !openingRung {
                openingRung = true
                ring(.opening, due: sitStart, now: now)
            }
            if now >= endDate && !targetRung {
                targetRung = true
                ring(.target, due: endDate, now: now)
            }
        }
    }

    /// The opening bell marks the start of the sit after the settling silence; the target bell
    /// marks the target. The sit carries on until the user taps End.
    private func ring(_ moment: Bell.Moment, due: Date, now: Date) {
        Bell.cancelNotification(for: moment)
        // The timer does not tick while the phone is locked. If the moment passed more than
        // a couple of seconds ago the notification already rang, so do not ring twice.
        if now.timeIntervalSince(due) < 2 { Bell.shared.ring() }
    }

    private func finish() {
        UIApplication.shared.isIdleTimerDisabled = false
        Bell.cancelNotifications()
        Bell.shared.stop()
        let end = Date()
        // An End during the settling silence records a sit of no length, not a negative one.
        onFinish(Session(start: min(sitStart, end), end: end, plannedSeconds: plannedSeconds,
                         completed: end >= endDate))
    }
}
