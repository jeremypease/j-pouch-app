import SwiftUI
import SwiftData

struct LogHydrationForm: View {
    @Environment(\.modelContext) private var modelContext

    private let quickAmountsML = [125, 250, 500]

    @State private var kind: HydrationKind = .water
    @State private var syncError: String?
    /// nil means "whenever the amount is tapped" — same reasoning as the output form.
    @State private var backdatedTo: Date?

    private var isBackdating: Bool { backdatedTo != nil }

    var body: some View {
        Form {
            Section("Type") {
                Picker("Type", selection: $kind) {
                    ForEach(HydrationKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Quick Add") {
                HStack {
                    ForEach(quickAmountsML, id: \.self) { amount in
                        Button("\(amount) mL") {
                            log(volumeML: amount)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section {
                Toggle("Log for an earlier time", isOn: Binding(
                    get: { isBackdating },
                    set: { backdatedTo = $0 ? .now : nil }
                ))
                if let backdatedTo {
                    DatePicker(
                        "When",
                        selection: Binding(
                            get: { backdatedTo },
                            set: { self.backdatedTo = $0 }
                        ),
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            } header: {
                Text("Time")
            } footer: {
                // Which day a drink lands on is what the hydration target and the dehydration
                // check actually care about, so catching up on yesterday needs to be possible.
                Text(isBackdating ? "Amounts you tap will be saved at this time." : "Amounts you tap are saved with the current time.")
            }

            if let syncError {
                Section {
                    Text(syncError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func log(volumeML: Int) {
        let timestamp = backdatedTo ?? .now
        let entry = HydrationEntry(timestamp: timestamp, volumeML: volumeML, kind: kind)
        modelContext.insert(entry)

        guard kind == .water else { return }
        // Explicitly main-actor rather than relying on the enclosing isolation being inferred:
        // both the SwiftData model and the @State below have to be touched on the main actor,
        // and a nonisolated continuation here would resume off it.
        Task { @MainActor in
            do {
                let sampleID = try await HealthKitManager.shared.logWater(volumeML: volumeML, date: timestamp)
                entry.healthKitSampleID = sampleID.uuidString
            } catch {
                syncError = "Saved locally, but couldn't sync to Health: \(error.localizedDescription)"
            }
        }
    }
}
