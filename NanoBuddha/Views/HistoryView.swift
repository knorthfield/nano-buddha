import SwiftUI

struct HistoryView: View {
    @Environment(Store.self) private var store
    @State private var copied = false

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
        .scrollContentBackground(.hidden)
        .background(Starfield())
        .navigationTitle("History")
        .toolbar {
            Button(copied ? "Copied" : "Copy week", systemImage: copied ? "checkmark" : "doc.on.doc") {
                UIPasteboard.general.string = WeekLog.markdown(sessions: store.sessions)
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    copied = false
                }
            }
            .accessibilityIdentifier("CopyWeek")
        }
    }
}
