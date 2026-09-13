import SwiftUI

struct HomeView: View {
    @Environment(Store.self) private var store
    @AppStorage(Bell.soundKey) private var soundOn = false
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if store.sessions.isEmpty {
                    Text("How long will you sit?")
                    Picker("Minutes", selection: Binding(
                        get: { store.intendedSeconds / 60 },
                        set: { store.intendedSeconds = $0 * 60 }
                    )) {
                        ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .frame(height: 60)
                } else {
                    NudgeRow()
                }
                PrimaryButton(title: "Begin", action: onStart)
                Toggle("Sound", isOn: $soundOn)
                    .padding(.horizontal, 8)
            }
        }
        .navigationTitle("Nano Buddha")
    }
}
