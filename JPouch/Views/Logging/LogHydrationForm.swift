import SwiftUI
import SwiftData

struct LogHydrationForm: View {
    @Environment(\.modelContext) private var modelContext

    private let quickAmountsML = [125, 250, 500]
    @State private var kind: HydrationKind = .water
    @State private var isSyncing = false
    @State private var syncError: String?

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
        let entry = HydrationEntry(volumeML: volumeML, kind: kind)
        modelContext.insert(entry)

        guard kind == .water else { return }
        // Explicitly main-actor rather than relying on the enclosing isolation being inferred:
        // both the SwiftData model and the @State below have to be touched on the main actor,
        // and a nonisolated continuation here would resume off it.
        Task { @MainActor in
            do {
                let sampleID = try await HealthKitManager.shared.logWater(volumeML: volumeML)
                entry.healthKitSampleID = sampleID.uuidString
            } catch {
                syncError = "Saved locally, but couldn't sync to Health: \(error.localizedDescription)"
            }
        }
    }
}
