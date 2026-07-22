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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(profile.stage.displayName)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.15), in: Capsule())

                    switch profile.stage {
                    case .adaptation:
                        HydrationCard(currentML: todaysHydrationML, targetML: profile.dailyHydrationTargetML)
                        OutputSummaryCard(count: todaysOutputCount)
                    case .longTermMaintenance:
                        PouchitisStatusCard()
                        HydrationCard(currentML: todaysHydrationML, targetML: profile.dailyHydrationTargetML)
                    case .preOp, .stagedSurgery:
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output Today").font(.headline)
            Text("\(count) entries logged")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PouchitisStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pattern Status", systemImage: "waveform.path.ecg")
                .font(.headline)
            Text("No pattern changes detected. Keep logging to build your baseline.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
