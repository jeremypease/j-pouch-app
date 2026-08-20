import AppIntents
import SwiftData
import WidgetKit

/// Logs a preset water amount directly from the widget, without opening the app.
///
/// Deliberately doesn't attempt a HealthKit sync the way `LogHydrationWizard` does in-app —
/// HealthKit authorization/writes aren't reliable from a widget extension's process without
/// separate entitlement/auth work, so a widget-logged water entry may not appear in Health.
/// That's a known v1 limitation, not a silent drop: the entry is still saved to the shared
/// SwiftData store either way, and the in-app wizard remains the reliable path to Health.
struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log water"
    static var description = IntentDescription("Logs a quick-add amount of water without opening J-Pouch.")

    @Parameter(title: "Amount (mL)")
    var volumeML: Int

    init() {
        volumeML = 250
    }

    init(volumeML: Int) {
        self.volumeML = volumeML
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = ModelContext(PersistenceSetup.shared.container)
        context.insert(HydrationEntry(timestamp: .now, volumeML: volumeML, kind: .water))
        try? context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "JPouchWidget")
        return .result()
    }
}

/// Repeats the most recent Output entry's consistency and blood level with a fresh timestamp —
/// the widget-space stand-in for the full step wizard, which needs more room than a widget has.
/// Deliberately doesn't copy urgency, pain, or notes: those feel too presumptive to silently
/// repeat without the person having looked at them again.
struct LogLastOutputIntent: AppIntent {
    static var title: LocalizedStringResource = "Repeat last output"
    static var description = IntentDescription("Logs a new output entry copying consistency and blood from your most recent entry.")

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = ModelContext(PersistenceSetup.shared.container)
        var descriptor = FetchDescriptor<OutputEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 1
        let last = try? context.fetch(descriptor).first

        context.insert(OutputEntry(
            timestamp: .now,
            consistency: last?.consistency ?? 4,
            blood: last?.blood ?? .none
        ))
        try? context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "JPouchWidget")
        return .result()
    }
}
