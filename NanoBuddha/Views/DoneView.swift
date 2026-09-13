import SwiftUI

struct DoneView: View {
    let session: Session
    let onDismiss: () -> Void
    #if !os(macOS) && !os(tvOS)
    @State private var healthStatus = "Saving to Health…"
    #endif
    #if os(tvOS)
    private let spacing = 32.0, symbolSize = 56.0, discSize = 160.0, bottomPadding = 60.0
    private let titleFont = Font.title, minutesFont = Font.title2
    #elseif os(watchOS)
    private let spacing = 8.0, symbolSize = 24.0, discSize = 56.0, bottomPadding = 0.0
    private let titleFont = Font.headline, minutesFont = Font.body
    #else
    private let spacing = 24.0, symbolSize = 36.0, discSize = 100.0, bottomPadding = 40.0
    private let titleFont = Font.title, minutesFont = Font.title2
    #endif

    var body: some View {
        VStack(spacing: spacing) {
            Spacer()
            Image(systemName: session.completed ? "checkmark" : "pause")
                .font(.system(size: symbolSize, weight: .light))
                .foregroundStyle(Color.accentColor)
                .frame(width: discSize, height: discSize)
                .glassEffect(.clear.tint(Color("GlassTint")), in: .circle)
            Text(session.completed ? "Session complete" : "Sit complete")
                .font(titleFont)
            Text("\(max(1, session.actualMinutes)) minutes")
                .font(minutesFont)
                .foregroundStyle(.secondary)
            #if !os(macOS) && !os(tvOS)
            Text(healthStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            #endif
            Spacer()
            PrimaryButton(title: "Done", action: onDismiss)
                .padding(.bottom, bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if !os(watchOS)
        .padding()
        .background(Starfield())
        #endif
        #if !os(macOS) && !os(tvOS)
        .task { healthStatus = await HealthWriter.save(session) }
        #endif
    }
}
