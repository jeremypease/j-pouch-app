import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile

    @Query(sort: \HydrationEntry.timestamp, order: .reverse) private var hydrationEntries: [HydrationEntry]
    @Query(sort: \OutputEntry.timestamp, order: .reverse) private var outputEntries: [OutputEntry]

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

                VStack(alignment: .leading, spacing: 20) {
                    Text(profile.stage.displayName)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.15), in: Capsule())

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
                }
                .padding()
            }
            .navigationTitle("J-Pouch")
        }
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
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.orange)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.orange.opacity(0.35))
        )
    }
}

private struct DehydrationFlagCard: View {
    let consecutiveDays: Int

    var body: some View {
        FlagCard(title: "Hydration worth watching", icon: "drop.triangle") {
            Text("For the last \(consecutiveDays) days your output has run above your usual while fluids stayed under your daily target. That combination is what tends to lead toward dehydration.")
                .font(.callout)
            Text("Electrolyte drinks often help more than water alone. If you're feeling lightheaded, unusually tired, or your urine is dark, contact your care team.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FlareFlagCard: View {
    let consecutiveDays: Int

    var body: some View {
        FlagCard(title: "This looks different from your normal", icon: "waveform.path.ecg") {
            Text("Over the last \(consecutiveDays) days your output has been well above your own baseline with blood present.")
                .font(.callout)
            Text("J-Pouch can't tell you what's causing this — it only notices that it's different for you. This is worth bringing to your GI.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 8) {
            Label("Pattern Status", systemImage: "waveform.path.ecg")
                .font(.headline)

            if isFlagged {
                Text("See the flags above. Keep logging — it's what makes these more accurate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let building = buildingBaseline {
                Text("Still learning what's normal for you — \(building.loggedDays) of \(building.daysNeeded) days logged. J-Pouch won't flag anything until it knows your baseline, since \"normal\" varies a lot between people.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let baseline = analysis.baselineOutputPerDay {
                Text("Nothing looks unusual against your recent baseline of about \(baseline, format: .number.precision(.fractionLength(0))) a day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Hydration").font(.headline)
            ProgressView(value: progress)
                .tint(.blue)
            Text("\(currentML) mL of \(targetML) mL today")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct OutputSummaryCard: View {
    let count: Int
    let baseline: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output Today").font(.headline)
            Text("\(count) logged")
                .font(.title2.bold())
            if let baseline {
                Text("Your usual is about \(baseline, format: .number.precision(.fractionLength(0))) a day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct UpcomingSurgeryCard: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Timeline").font(.headline)
            if let date = profile.stagedSurgeryDate ?? profile.takedownDate {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Set your surgery date in Settings to see it here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
