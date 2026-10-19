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
                    NudgeRow()
                }
                PrimaryButton(title: "Begin", action: onStart)
                Spacer()
                if !store.sessions.isEmpty {
                    Text("^[\(store.sessions.count) sit](inflect: true) · ^[\(store.totalMinutes) minute](inflect: true)")
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
}
