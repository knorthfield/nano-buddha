import SwiftUI

struct SitView: View {
    let plannedSeconds: Int
    let onFinish: (Session) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var endDate = Date()
    @State private var breathing = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ZStack {
                glow(size: 260, opacity: 0.45)
                    .offset(x: breathing ? 70 : -70, y: breathing ? -90 : 40)
                    .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: breathing)
                glow(size: 200, opacity: 0.3)
                    .offset(x: breathing ? -80 : 60, y: breathing ? 80 : -50)
                    .animation(.easeInOut(duration: 17).repeatForever(autoreverses: true), value: breathing)
                Color.clear
                    .frame(width: 160, height: 160)
                    .glassEffect(.clear, in: .circle)
                    .scaleEffect(breathing ? 1.12 : 1)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: breathing)
            }
            .accessibilityHidden(true)
            VStack {
                Spacer()
                Button("End") { finish(completed: false) }
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 40)
            }
        }
        .statusBarHidden()
        .onAppear {
            start = Date()
            endDate = start.addingTimeInterval(TimeInterval(plannedSeconds))
            Bell.scheduleNotification(at: endDate)
            UIApplication.shared.isIdleTimerDisabled = true
            breathing = !reduceMotion
        }
        .onReceive(tick) { now in
            if now >= endDate { finish(completed: true) }
        }
    }

    private func glow(size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(RadialGradient(colors: [Color.accentColor.opacity(opacity), .clear],
                                 center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
    }

    private func finish(completed: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        Bell.cancelNotification()
        if completed { Bell.ring() }
        onFinish(Session(start: start, end: completed ? endDate : Date(),
                         plannedSeconds: plannedSeconds, completed: completed))
    }
}
