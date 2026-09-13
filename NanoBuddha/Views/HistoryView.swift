import SwiftUI

struct HistoryView: View {
    @Environment(Store.self) private var store
    #if !os(tvOS)
    @State private var copied = false
    #endif

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
        #if !os(tvOS)
        .scrollContentBackground(.hidden)  // Not on tvOS, where the list is already clear.
        #endif
        .background(Starfield())
        .navigationTitle("History")
        #if !os(tvOS)
        .toolbar {
            Button(copied ? "Copied" : "Copy week", systemImage: copied ? "checkmark" : "doc.on.doc") {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(WeekLog.markdown(sessions: store.sessions), forType: .string)
                #else
                UIPasteboard.general.string = WeekLog.markdown(sessions: store.sessions)
                #endif
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    copied = false
                }
            }
            .accessibilityIdentifier("CopyWeek")
        }
        #endif
    }
}
