import SwiftUI

/// No first-run picker on the Mac: the nudge row starts from the 10 min default.
struct MacHomeView: View {
    @Environment(Store.self) private var store
    let onStart: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                HStack(spacing: 24) {
                    Button { store.nudge(by: -60) } label: { Image(systemName: "minus").frame(width: 24, height: 24) }
                        .accessibilityLabel("One minute less")
                        .disabled(store.intendedSeconds <= 60)
                    Text(store.intendedTimeText)
                        .font(.title)
                        .monospacedDigit()
                    Button { store.nudge(by: 60) } label: { Image(systemName: "plus").frame(width: 24, height: 24) }
                        .accessibilityLabel("One minute more")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                PrimaryButton(title: "Begin", action: onStart)
                Spacer()
                if !store.sessions.isEmpty {
                    Text("\(store.sessions.count) sits · \(store.totalSeconds / 60) minutes")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Starfield(secondsPerTurn: 72_000 / Double(store.intendedSeconds)))
            .navigationTitle("Nano Buddha")
            .toolbar {
                NavigationLink("History") { MacHistoryView() }
            }
        }
    }
}
