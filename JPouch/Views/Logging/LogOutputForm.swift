import SwiftUI
import SwiftData

struct LogOutputForm: View {
    @Environment(\.modelContext) private var modelContext

    @State private var consistency = 4
    @State private var hasUrgency = false
    @State private var urgencySeverity = 2
    @State private var blood: BloodLevel = .none
    @State private var pain = 0
    @State private var isNight = false
    @State private var notes = ""
    /// nil means "whenever Save is tapped". Deliberately not a plain Date defaulting to now:
    /// a form left open for an hour would otherwise save the time it was opened.
    @State private var backdatedTo: Date?
    @State private var didSave = false

    private var isBackdating: Bool { backdatedTo != nil }

    var body: some View {
        Form {
            Section {
                Stepper("Level \(consistency) of 7", value: $consistency, in: 1...7)
                Text(PouchConsistency.label(for: consistency))
                    .font(JPouchFont.bodyXS)
                    .foregroundStyle(JPouchColor.textSecondary)
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

            // Collapsed by default so the common case stays a two-tap save. Catching up on a
            // missed day matters: a day with nothing logged is a gap, and the pattern flags
            // deliberately break their streaks across gaps rather than guess.
            Section {
                Toggle("This happened earlier", isOn: Binding(
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
                Text(isBackdating ? "" : "Saves with the current time.")
            }

            Section("Notes") {
                TextField("Anything worth remembering", text: $notes, axis: .vertical)
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
                    .font(JPouchFont.bodyXS)
                    .fontWeight(.semibold)
                    .foregroundStyle(JPouchColor.textOnAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(JPouchColor.successSoft, in: Capsule())
                    .padding(.top, 8)
            }
        }
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = OutputEntry(
            timestamp: backdatedTo ?? .now,
            consistency: consistency,
            hasUrgency: hasUrgency,
            urgencySeverity: hasUrgency ? urgencySeverity : 0,
            blood: blood,
            pain: pain,
            isNight: isNight,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(entry)

        notes = ""
        backdatedTo = nil

        withAnimation { didSave = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            didSave = false
        }
    }
}
