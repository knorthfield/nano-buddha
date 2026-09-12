import SwiftUI

struct TVHistoryView: View {
    @Environment(Store.self) private var store

    var body: some View {
        List {
            Section {
                LabeledContent("Sits", value: "\(store.sessions.count)")
                LabeledContent("Total", value: "\(store.totalMinutes) min")
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
                        Text("\(session.actualMinutes) min")
                        if !session.completed {
                            Image(systemName: "pause.circle").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .background(Starfield())
        .navigationTitle("History")
    }
}
