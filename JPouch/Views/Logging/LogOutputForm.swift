import SwiftUI
import SwiftData

struct LogOutputForm: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var consistency = 4
    @State private var hasUrgency = false
    @State private var urgencySeverity = 2
    @State private var blood: BloodLevel = .none
    @State private var pain = 0
    @State private var isNight = false
    @State private var didSave = false

    var body: some View {
        Form {
            Section {
                Stepper("Level \(consistency) of 7", value: $consistency, in: 1...7)
                Text(PouchConsistency.label(for: consistency))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Consistency")
            } footer: {
                Text("Loosely adapted from the Bristol Stool Scale. Pouch output tends to run looser than typical stool, so mid-range is a common baseline.")
            }
            Section("Urgency") {
                Toggle("Felt urgent", isOn: $hasUrgency)
                if hasUrgency {
                    Stepper("Severity \(urgencySeverity) of 5", value: $urgencySeverity, in: 0...5)
                }
            }
            Section("Blood") {
                Picker("Blood", selection: $blood) {
                    ForEach(BloodLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Pain") {
                Stepper("\(pain) of 5", value: $pain, in: 0...5)
            }
            Section {
                Toggle("Nighttime episode", isOn: $isNight)
            }
            Section {
                Button {
                    save()
                } label: {
                    Text("Save Entry").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .overlay(alignment: .top) {
            if didSave {
                Text("Saved")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.2), in: Capsule())
                    .padding(.top, 8)
            }
        }
    }

    private func save() {
        let entry = OutputEntry(
            consistency: consistency,
            hasUrgency: hasUrgency,
            urgencySeverity: hasUrgency ? urgencySeverity : 0,
            blood: blood,
            pain: pain,
            isNight: isNight
        )
        modelContext.insert(entry)
        withAnimation {
            didSave = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            didSave = false
        }
    }
}
