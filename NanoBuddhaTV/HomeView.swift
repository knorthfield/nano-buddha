import SwiftUI

/// No first-run picker on the TV: the nudge row starts from the 10 min default.
struct HomeView: View {
    @Environment(Store.self) private var store
    let onStart: () -> Void
    @FocusState private var beginFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 48) {
                Spacer()
                NudgeRow()
                PrimaryButton(title: "Begin", action: onStart)
                    .focused($beginFocused)
                NavigationLink("History") { HistoryView() }
                    .buttonStyle(.glass)
                Spacer()
                if !store.sessions.isEmpty {
                    Text("^[\(store.sessions.count) sit](inflect: true) · ^[\(store.totalMinutes) minute](inflect: true)")
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
