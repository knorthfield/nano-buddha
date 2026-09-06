import SwiftUI

struct HomeView: View {
    @Environment(Store.self) private var store
    let onStart: (Int) -> Void

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Text("How long will you sit?")
                    .font(.title2)
                Picker("Minutes", selection: $store.lastNominalMinutes) {
                    ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                Button {
                    Bell.requestNotificationPermission()
                    onStart(store.lastNominalMinutes)
                } label: {
                    Text("Begin")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 48)
                Spacer()
                if !store.sessions.isEmpty {
                    Text("\(store.sessions.count) sits · \(store.totalSeconds / 60) minutes")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Nano Buddha")
            .toolbar {
                NavigationLink("History") { HistoryView() }
            }
        }
    }
}
