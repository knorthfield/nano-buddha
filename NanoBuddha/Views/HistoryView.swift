import SwiftUI

struct HistoryView: View {
    @Environment(Store.self) private var store

    var body: some View {
        List {
            Section {
                LabeledContent("Sits", value: "\(store.sessions.count)")
                LabeledContent("Total", value: "\(store.totalSeconds / 60) min")
                LabeledContent("Hidden growth", value: "+\(store.growthSeconds) s")
            }
            Section("Sessions") {
                ForEach(store.sessions.reversed()) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(session.start, style: .date)
                            Text(session.start, style: .time)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(session.actualSeconds / 60) min")
                        if !session.completed {
                            Image(systemName: "pause.circle").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Starfield())
        .navigationTitle("History")
    }
}
