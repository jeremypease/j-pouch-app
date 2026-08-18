import SwiftUI
import SwiftData

struct TrendsView: View {
    let profile: UserProfile

    @Query(sort: \OutputEntry.timestamp, order: .reverse) private var outputEntries: [OutputEntry]
    @Query(sort: \HydrationEntry.timestamp, order: .reverse) private var hydrationEntries: [HydrationEntry]
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var foodEntries: [FoodEntry]
    @Query(sort: \MedicationEntry.startDate, order: .reverse) private var medicationEntries: [MedicationEntry]

    @Environment(\.modelContext) private var modelContext

    @State private var windowDays = 30
    @State private var reportURL: URL?
    @State private var isGenerating = false
    @State private var generationFailed = false

    // Bounded slices so the lists stay readable. Held as arrays rather than slices so the
    // offsets handed back by onDelete index the same collection that was rendered.
    private var recentOutput: [OutputEntry] { Array(outputEntries.prefix(10)) }
    private var recentHydration: [HydrationEntry] { Array(hydrationEntries.prefix(10)) }
    private var recentFood: [FoodEntry] { Array(foodEntries.prefix(10)) }

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
                            Text("Generate GI visit report")
                        }
                    }
                    .disabled(isGenerating)

                    if let reportURL {
                        ShareLink(item: reportURL) {
                            Label("Share report", systemImage: "square.and.arrow.up")
                        }
                    }

                    if generationFailed {
                        Text("Couldn't build the report. Please try again.")
                            .font(JP.Font.caption)
                            .foregroundStyle(JP.Color.critical)
                    }
                } header: {
                    Text("GI visit report")
                } footer: {
                    Text("A summary of what you've logged over the selected period, to bring to an appointment. It reports your data and how it compares to your own baseline — it doesn't diagnose anything.")
                }

                Section("Recent output") {
                    if outputEntries.isEmpty {
                        Text("No entries yet.").foregroundStyle(JP.Color.secondaryText)
                    }
                    ForEach(recentOutput) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            (Text(entry.timestamp, style: .date) + Text(" \u{2022} ") + Text(entry.timestamp, style: .time))
                                .font(JP.Font.metricBody)
                            (Text("Consistency ")
                                + Text("\(entry.consistency)/7").font(JP.Font.metricCaption)
                                + Text(" \u{2022} Pain ")
                                + Text("\(entry.pain)/5").font(JP.Font.metricCaption)
                                + Text(entry.blood != .none ? " \u{2022} Blood: \(entry.blood.displayName)" : ""))
                                .font(JP.Font.caption)
                                .foregroundStyle(JP.Color.secondaryText)
                            if let notes = entry.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(JP.Font.caption)
                                    .italic()
                                    .foregroundStyle(JP.Color.secondaryText)
                            }
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { recentOutput[$0] }.forEach(modelContext.delete)
                    }
                }

                Section("Recent hydration") {
                    if hydrationEntries.isEmpty {
                        Text("No entries yet.").foregroundStyle(JP.Color.secondaryText)
                    }
                    ForEach(recentHydration) { entry in
                        AdaptiveLabeledRow(
                            label: Text("\(entry.volumeML) mL").font(JP.Font.metricBody)
                                + Text(" \u{2022} \(entry.kind.displayName)")
                        ) {
                            Text(entry.timestamp, style: .time)
                                .font(JP.Font.metricSmall)
                                .foregroundStyle(JP.Color.secondaryText)
                        }
                    }
                    .onDelete { offsets in
                        for entry in offsets.map({ recentHydration[$0] }) {
                            // Capture the HealthKit sample ID before deleting the local entry —
                            // once it's deleted the property is gone, and without this the
                            // written sample would be orphaned in Health forever.
                            if let sampleIDString = entry.healthKitSampleID,
                               let sampleID = UUID(uuidString: sampleIDString) {
                                Task { try? await HealthKitManager.shared.deleteWaterSample(id: sampleID) }
                            }
                            modelContext.delete(entry)
                        }
                    }
                }

                Section("Recent food") {
                    if foodEntries.isEmpty {
                        Text("No entries yet.").foregroundStyle(JP.Color.secondaryText)
                    }
                    ForEach(recentFood) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.foodDescription)
                            Text(entry.timestamp, style: .date)
                                .font(JP.Font.metricCaption)
                                .foregroundStyle(JP.Color.secondaryText)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { recentFood[$0] }.forEach(modelContext.delete)
                    }
                }

                Section {
                    if medicationEntries.isEmpty {
                        Text("Nothing tracked here.").foregroundStyle(JP.Color.secondaryText)
                    }
                    ForEach(medicationEntries) { medication in
                        VStack(alignment: .leading) {
                            Text(medication.name)
                            Text(medicationDetail(for: medication))
                                .font(JP.Font.caption)
                                .foregroundStyle(JP.Color.secondaryText)
                        }
                    }
                    .onDelete(perform: deleteMedications)
                } header: {
                    Text("Medications tracked in J-Pouch")
                } footer: {
                    Text("Swipe to delete. Deleting a course also cancels its reminders. Medications from the Health app aren't listed here — manage those in Health.")
                }
            }
            .navigationTitle("Trends")
            .onChange(of: windowDays) {
                // The existing file describes a different period, so don't leave it shareable.
                reportURL = nil
            }
        }
    }

    private func medicationDetail(for medication: MedicationEntry) -> String {
        var parts: [String] = []
        if !medication.dosage.isEmpty { parts.append(medication.dosage) }
        if medication.isAntibiotic { parts.append("antibiotic course") }
        if medication.reminderEnabled && !medication.reminderMinutesOfDay.isEmpty {
            parts.append("\(medication.reminderMinutesOfDay.count) reminder\(medication.reminderMinutesOfDay.count == 1 ? "" : "s")")
        }
        if let end = medication.endDate {
            parts.append(end < Calendar.current.startOfDay(for: .now) ? "finished" : "until \(end.formatted(date: .abbreviated, time: .omitted))")
        }
        return parts.isEmpty ? "Ongoing" : parts.joined(separator: " · ")
    }

    private func deleteMedications(at offsets: IndexSet) {
        for medication in offsets.map({ medicationEntries[$0] }) {
            // Capture the id first: after deletion the model is invalid, and the reminders are
            // keyed on it. Without this, deleting a course leaves its notifications firing.
            let id = medication.id
            modelContext.delete(medication)
            Task { await NotificationManager.shared.cancelReminders(forMedicationID: id) }
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
