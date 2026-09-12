import SwiftUI

struct HomeView: View {
    @Environment(Store.self) private var store
    let onStart: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                if store.sessions.isEmpty {
                    Text("How long will you sit?")
                        .font(.title2)
                    Picker("Minutes", selection: Binding(
                        get: { store.intendedSeconds / 60 },
                        set: { store.intendedSeconds = $0 * 60 }
                    )) {
                        ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 160)
                } else {
                    HStack(spacing: 24) {
                        Button { store.nudge(by: -60) } label: { Image(systemName: "minus").frame(width: 24, height: 24) }
                            .accessibilityLabel("One minute less")
                            .disabled(store.intendedSeconds <= 60)
                        Text(intendedTimeText)
                            .font(.title)
                            .monospacedDigit()
                        Button { store.nudge(by: 60) } label: { Image(systemName: "plus").frame(width: 24, height: 24) }
                            .accessibilityLabel("One minute more")
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                }
                PrimaryButton(title: "Begin") {
                    Bell.requestNotificationPermission()
                    onStart()
                }
                Spacer()
                if !store.sessions.isEmpty {
                    Text("\(store.sessions.count) sits · \(store.totalSeconds / 60) minutes")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Starfield(secondsPerTurn: 72_000 / Double(store.intendedSeconds)))
            .navigationTitle("Nano Buddha")
            .toolbar {
                NavigationLink("History") { HistoryView() }
            }
        }
    }

    private var intendedTimeText: String {
        let seconds = store.intendedSeconds
        var text = "\(seconds / 60) min"
        if seconds % 60 != 0 { text += " \(seconds % 60) s" }
        return text
    }
}
