import SwiftUI
import SwiftData

struct TrendsView: View {
    let profile: UserProfile

    @Query(sort: \OutputEntry.timestamp, order: .reverse) private var outputEntries: [OutputEntry]
    @Query(sort: \HydrationEntry.timestamp, order: .reverse) private var hydrationEntries: [HydrationEntry]
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var foodEntries: [FoodEntry]
    @Query(sort: \MedicationEntry.startDate, order: .reverse) private var medicationEntries: [MedicationEntry]

    @State private var windowDays = 30
    @State private var reportURL: URL?
    @State private var isGenerating = false
    @State private var generationFailed = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Period", selection: $windowDays) {
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                    }
                    .pickerStyle(.segmented)

                    Button {
                        Task { await generateReport() }
                    } label: {
                        if isGenerating {
                            HStack {
                                ProgressView()
                                Text("Generating…")
                            }
                        } else {
                            Text("Generate GI Visit Report")
                        }
                    }
                    .disabled(isGenerating)

                    if let reportURL {
                        ShareLink(item: reportURL) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                        }
                    }

                    if generationFailed {
                        Text("Couldn't build the report. Please try again.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("GI Visit Report")
                } footer: {
                    Text("A summary of what you've logged over the selected period, to bring to an appointment. It reports your data and how it compares to your own baseline — it doesn't diagnose anything.")
                }

                Section("Recent Output") {
                    if outputEntries.isEmpty {
                        Text("No entries yet.").foregroundStyle(.secondary)
                    }
                    ForEach(outputEntries.prefix(10)) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.timestamp, style: .date) + Text(" \u{2022} ") + Text(entry.timestamp, style: .time)
                            Text("Consistency \(entry.consistency)/7 \u{2022} Pain \(entry.pain)/5\(entry.blood != .none ? " \u{2022} Blood: \(entry.blood.displayName)" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Recent Hydration") {
                    if hydrationEntries.isEmpty {
                        Text("No entries yet.").foregroundStyle(.secondary)
                    }
                    ForEach(hydrationEntries.prefix(10)) { entry in
                        Text("\(entry.volumeML) mL \u{2022} \(entry.kind.displayName)")
                    }
                }
            }
            .navigationTitle("Trends")
            .onChange(of: windowDays) {
                // The existing file describes a different period, so don't leave it shareable.
                reportURL = nil
            }
        }
    }

    private func generateReport() async {
        isGenerating = true
        generationFailed = false
        reportURL = nil

        // Give SwiftUI a chance to paint the spinner before the main thread is tied up.
        // The work itself has to stay on the main actor — the SwiftData models below are
        // bound to it — so this makes progress visible rather than truly backgrounding it.
        await Task.yield()

        let report = ReportBuilder.build(
            windowDays: windowDays,
            outputs: outputEntries,
            hydration: hydrationEntries,
            foods: foodEntries,
            medications: medicationEntries,
            stageName: profile.stage.displayName,
            hydrationTargetML: profile.dailyHydrationTargetML
        )

        let fileName = "J-Pouch Summary \(Self.fileDateFormatter.string(from: .now)).pdf"
        reportURL = ReportPDFRenderer.writePDF(for: report, fileName: fileName)
        generationFailed = reportURL == nil
        isGenerating = false
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
