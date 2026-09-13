import SwiftUI
import WidgetKit

struct SitEntry: TimelineEntry {
    let date: Date
    let intendedMinutes: Int
    let weekSits: Int
    let weekMinutes: Int
}

/// One entry, refreshed when the app saves the store.
struct SitProvider: TimelineProvider {
    func placeholder(in context: Context) -> SitEntry {
        SitEntry(date: .now, intendedMinutes: 10, weekSits: 5, weekMinutes: 52)
    }

    func getSnapshot(in context: Context, completion: @escaping (SitEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SitEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .never))
    }

    private func current() -> SitEntry {
        let store = Store()
        let week = store.sessions.inLast(days: 7)
        let weekSeconds = week.reduce(0) { $0 + $1.actualSeconds }
        return SitEntry(date: .now,
                        intendedMinutes: store.intendedSeconds / 60,
                        weekSits: week.count,
                        weekMinutes: Int((Double(weekSeconds) / 60).rounded()))
    }
}

struct SitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SitEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text("\(entry.intendedMinutes) min · \(entry.weekSits) sits this week")
            #if os(watchOS)
            case .accessoryCorner:
                Text("\(entry.intendedMinutes)").font(.title2.bold()).monospacedDigit()
                    .widgetLabel("\(entry.weekSits) sits this week")
            #endif
            case .accessoryCircular:
                VStack(spacing: 0) {
                    Text("\(entry.intendedMinutes)").font(.title2.bold()).monospacedDigit()
                    Text("min").font(.caption2)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nano Buddha").font(.headline)
                    Text("\(entry.intendedMinutes) min next")
                    Text("\(entry.weekSits) sits · \(entry.weekMinutes) min, 7 days").font(.caption)
                }
            default:
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(entry.intendedMinutes) min").font(.largeTitle.bold()).monospacedDigit()
                    Spacer()
                    Text("\(entry.weekSits) sits · \(entry.weekMinutes) min")
                    Text("last 7 days").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .containerBackground(for: .widget) {
            if family == .accessoryCircular {
                AccessoryWidgetBackground()
            } else {
                #if os(watchOS)
                Color.clear
                #else
                Color(.systemBackground)
                #endif
            }
        }
    }
}

struct SitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.krisnorthfield.NanoBuddha.sit", provider: SitProvider()) { entry in
            SitWidgetView(entry: entry)
        }
        .configurationDisplayName("Nano Buddha")
        .description("Your next sit and the last seven days.")
        #if os(watchOS)
        .supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        #else
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        #endif
    }
}
