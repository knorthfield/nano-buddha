import SwiftUI
import WidgetKit

struct SitEntry: TimelineEntry {
    let date: Date
    let intendedMinutes: Int
    let weekSits: Int
    let weekMinutes: Int
}

/// One entry, refreshed when the app saves the store and at midnight, when the 7-day window moves.
struct SitProvider: TimelineProvider {
    func placeholder(in context: Context) -> SitEntry {
        SitEntry(date: .now, intendedMinutes: 10, weekSits: 5, weekMinutes: 52)
    }

    func getSnapshot(in context: Context, completion: @escaping (SitEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SitEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        completion(Timeline(entries: [current()], policy: .after(midnight)))
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

    private var isExtraLarge: Bool {
        #if os(watchOS)
        false
        #else
        if family == .systemExtraLarge { return true }
        if #available(iOS 27, macOS 27, *) { return family == .systemExtraLargePortrait }
        return false
        #endif
    }

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
                    Text("^[\(entry.weekSits) sit](inflect: true) · \(entry.weekMinutes) min, 7 days").font(.caption)
                }
            #endif
            default:
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(entry.intendedMinutes) min", systemImage: Self.symbol)
                        .font(isExtraLarge ? .system(size: 80, weight: .bold) : .largeTitle.bold())
                        .monospacedDigit()
                    Spacer()
                    Text("^[\(entry.weekSits) sit](inflect: true) · \(entry.weekMinutes) min")
                    Text("last 7 days").foregroundStyle(.secondary)
                }
                .font(isExtraLarge ? .largeTitle : .subheadline)
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
        .supportedFamilies(families)
    }

    private var families: [WidgetFamily] {
        #if os(watchOS)
        return [.accessoryCorner, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #else
        #if os(macOS)
        var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemExtraLarge]
        #else
        var families: [WidgetFamily] = [.systemSmall, .systemExtraLarge,
                                        .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #endif
        // Extra large portrait is new in OS 27.
        if #available(iOS 27, macOS 27, *) { families.append(.systemExtraLargePortrait) }
        return families
        #endif
    }
}
