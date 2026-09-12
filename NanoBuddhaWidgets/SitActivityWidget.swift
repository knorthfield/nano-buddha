import ActivityKit
import SwiftUI
import WidgetKit

struct SitActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SitAttributes.self) { _ in
            HStack {
                Label("Sitting", systemImage: "figure.mind.and.body")
                    .font(.headline)
                Spacer()
                EndButton()
            }
            .padding()
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Label("Sitting", systemImage: "figure.mind.and.body")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EndButton()
                }
            } compactLeading: {
                Image(systemName: "figure.mind.and.body")
            } compactTrailing: {
                EmptyView()
            } minimal: {
                Image(systemName: "figure.mind.and.body")
            }
        }
    }
}

private struct EndButton: View {
    var body: some View {
        Button(intent: EndSitIntent()) {
            Text("End")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("AccentColor"))
    }
}
