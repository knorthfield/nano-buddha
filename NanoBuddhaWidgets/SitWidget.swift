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
    private static let symbol = "figure.mind.and.body"

    var body: some View {
        Group {
            switch family {
            #if !os(macOS)
            case .accessoryInline:
                Label {
                    Text("\(entry.intendedMinutes) min · \(entry.weekSits) sits this week")
                } icon: {
                    Image(systemName: Self.symbol)
                }
            #if os(watchOS)
            case .accessoryCorner:
                Image(systemName: Self.symbol).font(.title2).widgetAccentable()
                    .widgetLabel("\(entry.intendedMinutes) min · \(entry.weekSits) sits")
            #endif
            case .accessoryCircular:
                VStack(spacing: 0) {
                    Image(systemName: Self.symbol).font(.caption)
                    Text("\(entry.intendedMinutes)").font(.title2.bold()).monospacedDigit()
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Label("Nano Buddha", systemImage: Self.symbol).font(.headline)
                    Text("\(entry.intendedMinutes) min next")
                    Text("\(entry.weekSits) sits · \(entry.weekMinutes) min, 7 days").font(.caption)
                }
            #endif
            default:
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(entry.intendedMinutes) min", systemImage: Self.symbol)
                        .font(.largeTitle.bold()).monospacedDigit()
                    Spacer()
                    Text("\(entry.weekSits) sits · \(entry.weekMinutes) min")
                    Text("last 7 days").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .containerBackground(for: .widget) {
            #if os(macOS)
            Color(nsColor: .windowBackgroundColor)
            #else
            if family == .accessoryCircular {
                AccessoryWidgetBackground()
            } else {
                #if os(watchOS)
                Color.clear
                #else
                Color(.systemBackground)
                #endif
            }
            #endif
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
        #elseif os(macOS)
        .supportedFamilies([.systemSmall, .systemMedium])
        #else
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        #endif
    }
}
