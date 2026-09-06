import SwiftUI

struct SitView: View {
    let plannedSeconds: Int
    let onFinish: (Session) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var endDate = Date()
    @State private var breathing = false
    @State private var highlightTurning = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Starfield()
            Color.clear
                .frame(width: 160, height: 160)
                .glassEffect(.clear.tint(.black.opacity(0.45)), in: .circle)
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
            highlightTurning = !reduceMotion
        }
        .onReceive(tick) { now in
            if now >= endDate { finish(completed: true) }
        }
    }

    private func finish(completed: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        Bell.cancelNotification()
        if completed { Bell.ring() }
        onFinish(Session(start: start, end: completed ? endDate : Date(),
                         plannedSeconds: plannedSeconds, completed: completed))
    }
}
