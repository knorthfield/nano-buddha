import SwiftUI

struct DoneView: View {
    let session: Session
    let onDismiss: () -> Void
    @State private var healthStatus = "Saving to Health…"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: session.completed ? "checkmark.circle" : "pause.circle")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(Color.accentColor)
            Text(session.completed ? "Session complete" : "Ended early")
                .font(.title)
            Text("\(max(1, session.actualSeconds / 60)) minutes")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(healthStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
        }
        .padding()
        .background(Starfield())
        .task { healthStatus = await HealthWriter.save(session) }
    }
}
