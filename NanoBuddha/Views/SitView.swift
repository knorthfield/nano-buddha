import SwiftUI

struct SitView: View {
    let plannedSeconds: Int
    let settlingSeconds: Int
    let onFinish: (Session) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sit = Sit()
    @State private var breathing = false
    @State private var highlightTurning = false
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
            sit.start(settlingSeconds: settlingSeconds, plannedSeconds: plannedSeconds)
            SitActivity.start()
            UIApplication.shared.isIdleTimerDisabled = true
            breathing = !reduceMotion
            highlightTurning = !reduceMotion
        }
        .onReceive(tick) { now in sit.tick(now: now) }
        // The End button on the Live Activity runs its intent in this process.
        .onReceive(NotificationCenter.default.publisher(for: SitActivity.endRequested)) { _ in finish() }
    }

    private func finish() {
        UIApplication.shared.isIdleTimerDisabled = false
        SitActivity.end()
        onFinish(sit.finish())
    }
}
