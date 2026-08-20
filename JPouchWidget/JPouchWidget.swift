import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct JPouchWidgetEntry: TimelineEntry {
    let date: Date
    let todayHydrationML: Int
    let hydrationTargetML: Int
}

struct JPouchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> JPouchWidgetEntry {
        JPouchWidgetEntry(date: .now, todayHydrationML: 0, hydrationTargetML: 2000)
    }

    func getSnapshot(in context: Context, completion: @escaping (JPouchWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JPouchWidgetEntry>) -> Void) {
        // Content only changes when a quick-log intent calls WidgetCenter.reloadTimelines, not on
        // a schedule, so one entry with no further refresh is enough.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> JPouchWidgetEntry {
        let context = ModelContext(PersistenceSetup.shared.container)
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let hydrationDescriptor = FetchDescriptor<HydrationEntry>(
            predicate: #Predicate { $0.timestamp >= startOfDay }
        )
        let todayTotal = (try? context.fetch(hydrationDescriptor))?.reduce(0) { $0 + $1.volumeML } ?? 0
        let target = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first?.dailyHydrationTargetML ?? 2000

        return JPouchWidgetEntry(date: .now, todayHydrationML: todayTotal, hydrationTargetML: target)
    }
}

struct JPouchWidgetView: View {
    var entry: JPouchWidgetProvider.Entry

    private let presetAmountsML = [125, 250, 500]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hydration today")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(entry.todayHydrationML) / \(entry.hydrationTargetML) mL")
                .font(.headline)

            HStack(spacing: 6) {
                ForEach(presetAmountsML, id: \.self) { amount in
                    Button(intent: LogWaterIntent(volumeML: amount)) {
                        Text("+\(amount)")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button(intent: LogLastOutputIntent()) {
                Text("Log last output")
                    .font(.caption2)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

struct JPouchWidget: Widget {
    let kind = "JPouchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JPouchWidgetProvider()) { entry in
            JPouchWidgetView(entry: entry)
        }
        .configurationDisplayName("J-Pouch Quick Log")
        .description("Log water or repeat your last output entry without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct JPouchWidgetBundle: WidgetBundle {
    var body: some Widget {
        JPouchWidget()
    }
}
