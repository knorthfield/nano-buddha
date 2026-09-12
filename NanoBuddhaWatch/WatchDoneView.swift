import SwiftUI

struct WatchDoneView: View {
    let session: Session
    let onDismiss: () -> Void
    @State private var healthStatus = "Saving to Health…"

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: session.completed ? "checkmark" : "pause")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Color.accentColor)
                .frame(width: 56, height: 56)
                .glassEffect(.clear.tint(Color("GlassTint")), in: .circle)
            Text(session.completed ? "Session complete" : "Sit complete")
                .font(.headline)
            Text("\(max(1, session.actualMinutes)) minutes")
                .foregroundStyle(.secondary)
            Text(healthStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Done", action: onDismiss)
        }
        .task { healthStatus = await HealthWriter.save(session) }
    }
}
