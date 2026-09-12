import SwiftUI

/// No first-run picker on the TV: the nudge row starts from the 10 min default.
struct TVHomeView: View {
    @Environment(Store.self) private var store
    let onStart: () -> Void
    @FocusState private var beginFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 48) {
                Spacer()
                HStack(spacing: 40) {
                    Button { store.nudge(by: -60) } label: { Image(systemName: "minus").frame(width: 40, height: 40) }
                        .accessibilityLabel("One minute less")
                        .disabled(store.intendedSeconds <= 60)
                    Text(store.intendedTimeText)
                        .font(.largeTitle)
                        .monospacedDigit()
                    Button { store.nudge(by: 60) } label: { Image(systemName: "plus").frame(width: 40, height: 40) }
                        .accessibilityLabel("One minute more")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                PrimaryButton(title: "Begin", action: onStart)
                    .focused($beginFocused)
                NavigationLink("History") { TVHistoryView() }
                    .buttonStyle(.glass)
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
            .defaultFocus($beginFocused, true)
        }
    }
}
