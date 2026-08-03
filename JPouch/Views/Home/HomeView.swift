import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile
    @Binding var selectedTab: MainTab

    @Query(sort: \HydrationEntry.timestamp, order: .reverse) private var hydrationEntries: [HydrationEntry]
    @Query(sort: \OutputEntry.timestamp, order: .reverse) private var outputEntries: [OutputEntry]
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var symptomEntries: [SymptomEntry]

    @State private var isShowingSymptomCheckIn = false

    private var todaysHydrationML: Int {
        hydrationEntries
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.volumeML }
    }

    private var todaysOutputCount: Int {
        outputEntries.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    private var patternAnalysis: PatternAnalyzer.Analysis {
        let summaries = PatternAnalyzer.dailySummaries(outputs: outputEntries, hydration: hydrationEntries)
        return PatternAnalyzer.analyze(summaries: summaries, hydrationTargetML: profile.dailyHydrationTargetML)
    }

    /// Pattern flags are relevant from the first surgery onward — dehydration is a real risk
    /// with a high-output ileostomy too, and pouchitis risk is lifelong rather than something
    /// that only starts once someone is years out.
    private var showsPatternFlags: Bool {
        profile.stage != .preOp
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let analysis = patternAnalysis

                VStack(alignment: .leading, spacing: JP.Spacing.lg) {
                    GreetingHeader(stage: profile.stage)

                    JourneyStrip(currentStage: profile.stage) {
                        selectedTab = .settings
                    }

                    QuickActions(
                        onLogOutput: { selectedTab = .log },
                        onSymptomCheckIn: { isShowingSymptomCheckIn = true }
                    )

                    if showsPatternFlags {
                        if case .flagged(let days) = analysis.flare {
                            FlareFlagCard(consecutiveDays: days)
                        }
                        if case .flagged(let days) = analysis.dehydration {
                            DehydrationFlagCard(consecutiveDays: days)
                        }
                    }

                    switch profile.stage {
                    case .adaptation:
                        HydrationCard(currentML: todaysHydrationML, targetML: profile.dailyHydrationTargetML)
                        OutputSummaryCard(count: todaysOutputCount, baseline: analysis.baselineOutputPerDay)
                        PatternStatusCard(analysis: analysis)
                    case .longTermMaintenance:
                        PatternStatusCard(analysis: analysis)
                        HydrationCard(currentML: todaysHydrationML, targetML: profile.dailyHydrationTargetML)
                        OutputSummaryCard(count: todaysOutputCount, baseline: analysis.baselineOutputPerDay)
                    case .stagedSurgery:
                        HydrationCard(currentML: todaysHydrationML, targetML: profile.dailyHydrationTargetML)
                        UpcomingSurgeryCard(profile: profile)
                    case .preOp:
                        UpcomingSurgeryCard(profile: profile)
                        HydrationCard(currentML: todaysHydrationML, targetML: profile.dailyHydrationTargetML)
                    }

                    TodaysLogCard(
                        outputs: todaysEntries(outputEntries),
                        hydration: todaysEntries(hydrationEntries),
                        symptoms: todaysEntries(symptomEntries)
                    )

                    // Sends people to Log, not Settings: medication reminders are configured on
                    // the Meds form, and Settings has no reminders section to land on.
                    RemindersShortcut { selectedTab = .log }
                }
                .padding(JP.Spacing.lg)
            }
            .background(JP.Color.pageBackground)
            .navigationTitle("J-Pouch")
            .sheet(isPresented: $isShowingSymptomCheckIn) {
                SymptomCheckInView()
            }
        }
    }

    private func todaysEntries<T: Timestamped>(_ entries: [T]) -> [T] {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }
    }
}

/// Lets Home treat the four entry types uniformly for "what happened today" without each of
/// them needing to know about the others.
protocol Timestamped {
    var timestamp: Date { get }
}

extension OutputEntry: Timestamped {}
extension HydrationEntry: Timestamped {}
extension SymptomEntry: Timestamped {}

// MARK: - Header

private struct GreetingHeader: View {
    let stage: Stage

    /// Time-of-day rather than a name: the app never asks for one, and "Good evening" at 2am
    /// would be its own small insult on a night someone is up because of their pouch.
    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Still up?"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            Text(greeting)
                .font(JP.Font.displayLarge)
                .foregroundStyle(JP.Color.primaryText)
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(JP.Font.callout)
                .foregroundStyle(JP.Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Journey

/// Where someone is across the four stages, as a strip rather than a single badge.
///
/// Seeing the whole arc matters more than the current label alone: pre-op and staged-surgery
/// users are looking at a path they haven't finished, and adaptation ends.
private struct JourneyStrip: View {
    let currentStage: Stage
    let onTap: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var currentIndex: Int {
        Stage.allCases.firstIndex(of: currentStage) ?? 0
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                HStack {
                    Text("Your journey")
                        .font(JP.Font.label)
                        .foregroundStyle(JP.Color.secondaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(JP.Color.secondaryText)
                        .accessibilityHidden(true)
                }

                Text(currentStage.displayName)
                    .font(JP.Font.title)
                    .foregroundStyle(JP.Color.primaryText)

                // The dot strip is decorative shorthand for the same information the stage name
                // already gives, so it stays out of VoiceOver — and it's dropped entirely at
                // accessibility sizes, where four segments plus padding stop fitting.
                if !dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: JP.Spacing.xs) {
                        ForEach(Array(Stage.allCases.enumerated()), id: \.element) { index, _ in
                            Capsule()
                                .fill(index <= currentIndex ? JP.Color.brandFill : JP.Color.separator)
                                .frame(height: 6)
                        }
                    }
                    .accessibilityHidden(true)
                }

                Text(currentStage.summary)
                    .font(JP.Font.caption)
                    .foregroundStyle(JP.Color.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            .jpCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Settings, where you can change your stage")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Quick actions

private struct QuickActions: View {
    let onLogOutput: () -> Void
    let onSymptomCheckIn: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Side by side normally, stacked once the labels need the width — two cards sharing a
        // row truncate "Symptom check-in" badly at larger sizes.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: JP.Spacing.md))
            : AnyLayout(HStackLayout(spacing: JP.Spacing.md))

        layout {
            QuickActionCard(
                title: "Log output",
                icon: "drop.circle.fill",
                action: onLogOutput
            )
            QuickActionCard(
                title: "Symptom check-in",
                icon: "heart.text.square.fill",
                action: onSymptomCheckIn
            )
        }
    }
}

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                JPIconCircle(systemImage: icon)
                Text(title)
                    .font(JP.Font.subheading)
                    .foregroundStyle(JP.Color.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .jpCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Pattern flags

/// Shared treatment for raised flags. Deliberately amber rather than red: this is a "worth a
/// conversation" signal, not an emergency, and never a diagnosis.
private struct FlagCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            JPCardHeader(title: title, icon: icon, tint: JP.Color.attention)
            content
        }
        .jpCard(tint: JP.Color.attention)
    }
}

private struct DehydrationFlagCard: View {
    let consecutiveDays: Int

    var body: some View {
        FlagCard(title: "Hydration worth watching", icon: "drop.triangle") {
            Text("For the last \(consecutiveDays) days your output has run above your usual while fluids stayed under your daily target. That combination is what tends to lead toward dehydration.")
                .font(JP.Font.callout)
            JPCaption("Electrolyte drinks often help more than water alone. If you're feeling lightheaded, unusually tired, or your urine is dark, contact your care team.")
        }
    }
}

private struct FlareFlagCard: View {
    let consecutiveDays: Int

    var body: some View {
        FlagCard(title: "This looks different from your normal", icon: "waveform.path.ecg") {
            Text("Over the last \(consecutiveDays) days your output has been well above your own baseline with blood present.")
                .font(JP.Font.callout)
            JPCaption("J-Pouch can't tell you what's causing this — it only notices that it's different for you. This is worth bringing to your GI.")
        }
    }
}

/// The persistent status card. Critically, this only claims nothing looks unusual once there's
/// actually enough logged history to make that claim — otherwise it says so plainly rather
/// than offering false reassurance.
private struct PatternStatusCard: View {
    let analysis: PatternAnalyzer.Analysis

    private var isFlagged: Bool {
        if case .flagged = analysis.flare { return true }
        if case .flagged = analysis.dehydration { return true }
        return false
    }

    /// If *either* check is still building its baseline, say so rather than implying both have
    /// been evaluated — the two use slightly different windows, so they can differ at the edge.
    private var buildingBaseline: (loggedDays: Int, daysNeeded: Int)? {
        for status in [analysis.dehydration, analysis.flare] {
            if case .buildingBaseline(let loggedDays, let daysNeeded) = status {
                return (loggedDays, daysNeeded)
            }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            JPCardHeader(title: "Pattern Status", icon: "waveform.path.ecg")

            if isFlagged {
                JPCaption("See the flags above. Keep logging — it's what makes these more accurate.")
            } else if let building = buildingBaseline {
                JPCaption("Still learning what's normal for you — \(building.loggedDays) of \(building.daysNeeded) days logged. J-Pouch won't flag anything until it knows your baseline, since \"normal\" varies a lot between people.")
            } else if let baseline = analysis.baselineOutputPerDay {
                JPCaption("Nothing looks unusual against your recent baseline of about \(baseline.formatted(.number.precision(.fractionLength(0)))) a day.")
            }
        }
        .jpCard()
    }
}

// MARK: - Everyday cards

private struct HydrationCard: View {
    let currentML: Int
    let targetML: Int

    private var progress: Double {
        guard targetML > 0 else { return 0 }
        return min(Double(currentML) / Double(targetML), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Hydration", icon: "drop.fill")

            // The figure leads, the bar supports it. Previously the only number on this card was
            // caption-grey under a hairline bar, which made the app's primary daily metric the
            // least legible thing on the screen.
            JPMetric(value: "\(currentML)", unit: "mL")
            JPProgressBar(progress: progress)
            JPCaption("of \(targetML) mL today")
        }
        .jpCard()
        .accessibilityElement(children: .combine)
    }
}

private struct OutputSummaryCard: View {
    let count: Int
    let baseline: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Output Today", icon: "chart.bar.fill")
            JPMetric(value: "\(count)", unit: count == 1 ? "entry" : "entries")
            if let baseline {
                JPCaption("Your usual is about \(baseline.formatted(.number.precision(.fractionLength(0)))) a day.")
            }
        }
        .jpCard()
        .accessibilityElement(children: .combine)
    }
}

private struct UpcomingSurgeryCard: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            JPCardHeader(title: "Your Timeline", icon: "calendar")
            if let date = profile.stagedSurgeryDate ?? profile.takedownDate {
                Text(date, style: .date)
                    .font(JP.Font.bodyMedium)
            } else {
                JPCaption("Set your surgery date in Settings to see it here.")
            }
        }
        .jpCard()
    }
}

// MARK: - Today's log

private struct TodaysLogCard: View {
    let outputs: [OutputEntry]
    let hydration: [HydrationEntry]
    let symptoms: [SymptomEntry]

    /// `PersistentIdentifier` is unique across entities, so it identifies a row on its own —
    /// no need to prefix it with the type it came from.
    private struct Row: Identifiable {
        let id: PersistentIdentifier
        let time: Date
        let icon: String
        let text: String
    }

    private var rows: [Row] {
        let outputRows = outputs.map {
            Row(
                id: $0.persistentModelID,
                time: $0.timestamp,
                icon: "drop.circle.fill",
                text: "Output · consistency \($0.consistency)/7"
            )
        }
        let hydrationRows = hydration.map {
            Row(
                id: $0.persistentModelID,
                time: $0.timestamp,
                icon: "waterbottle.fill",
                text: "\($0.volumeML) mL · \($0.kind.displayName)"
            )
        }
        let symptomRows = symptoms.map {
            Row(
                id: $0.persistentModelID,
                time: $0.timestamp,
                icon: "heart.text.square.fill",
                text: $0.summaryLine
            )
        }
        return (outputRows + hydrationRows + symptomRows).sorted { $0.time > $1.time }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Today's log", icon: "list.bullet.rectangle")

            if rows.isEmpty {
                JPCaption("Nothing logged yet today.")
            } else {
                ForEach(rows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: JP.Spacing.md) {
                        Image(systemName: row.icon)
                            .foregroundStyle(JP.Color.accent)
                            .accessibilityHidden(true)
                        Text(row.text)
                            .font(JP.Font.callout)
                            .foregroundStyle(JP.Color.primaryText)
                        Spacer(minLength: JP.Spacing.sm)
                        Text(row.time, style: .time)
                            .font(JP.Font.metricSmall)
                            .foregroundStyle(JP.Color.secondaryText)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .jpCard()
    }
}

// MARK: - Reminders

private struct RemindersShortcut: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: JP.Spacing.md) {
                JPIconCircle(systemImage: "bell.fill", size: 36)
                VStack(alignment: .leading, spacing: JP.Spacing.xs) {
                    Text("Reminders")
                        .font(JP.Font.subheading)
                        .foregroundStyle(JP.Color.primaryText)
                    Text("Set medication times under Log → Meds")
                        .font(JP.Font.caption)
                        .foregroundStyle(JP.Color.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: JP.Spacing.sm)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(JP.Color.secondaryText)
                    .accessibilityHidden(true)
            }
            .jpCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
