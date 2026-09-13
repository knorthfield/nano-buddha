import SwiftUI

struct DoneView: View {
    let session: Session
    let onDismiss: () -> Void
    #if !os(macOS)
    @State private var healthStatus = "Saving to Health…"
    #endif

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
            #if !os(macOS)
            Text(healthStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
            #endif
            Spacer()
            PrimaryButton(title: "Done", action: onDismiss)
                .padding(.bottom, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Starfield())
        #if !os(macOS)
        .task { healthStatus = await HealthWriter.save(session) }
        #endif
    }
}
