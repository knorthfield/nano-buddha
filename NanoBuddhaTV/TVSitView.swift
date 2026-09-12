import SwiftUI

struct TVSitView: View {
    let plannedSeconds: Int
    let settlingSeconds: Int
    let onFinish: (Session) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sit = Sit()
    @State private var breathing = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Starfield()
            Color.clear
                .frame(width: 240, height: 240)
                .glassEffect(.clear.tint(Color("GlassTint")), in: .circle)
                .scaleEffect(breathing ? 1.08 : 1)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: breathing)
                .accessibilityHidden(true)
            VStack {
                Spacer()
                PrimaryButton(title: "End") { finish() }
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            sit.start(settlingSeconds: settlingSeconds, plannedSeconds: plannedSeconds)
            UIApplication.shared.isIdleTimerDisabled = true
            breathing = !reduceMotion
        }
        .onReceive(tick) { now in sit.tick(now: now) }
        // The remote's Menu/Back button ends the sit rather than leaving it running behind the TV home screen.
        .onExitCommand { finish() }
    }

    private func finish() {
        UIApplication.shared.isIdleTimerDisabled = false
        onFinish(sit.finish())
    }
}
