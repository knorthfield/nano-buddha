import SwiftUI

struct SitView: View {
    let plannedSeconds: Int
    let onFinish: (Session) -> Void

    @State private var start = Date()
    @State private var endDate = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                Image(systemName: "circle")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.4))
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
