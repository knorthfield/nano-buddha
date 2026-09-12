import SwiftUI

struct DoneView: View {
    let session: Session
    let onDismiss: () -> Void
    @State private var healthStatus = "Saving to Health…"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: session.completed ? "checkmark" : "pause")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.accentColor)
                .frame(width: 100, height: 100)
                .glassEffect(.clear.tint(Color("GlassTint")), in: .circle)
            Text(session.completed ? "Session complete" : "Sit complete")
                .font(.title)
            Text("\(max(1, session.actualMinutes)) minutes")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(healthStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            PrimaryButton(title: "Done", action: onDismiss)
                .padding(.bottom, 40)
        }
        .padding()
        .background(Starfield())
        .task { healthStatus = await HealthWriter.save(session) }
    }
}
