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
        ScrollView {
            VStack(alignment: .leading, spacing: JP.Spacing.lg) {
                consistencySection
                urgencySection
                bloodSection
                painSection
                timeSection
                notesSection

                Button("Save Entry") { save() }
                    .buttonStyle(.jpPrimary)
                    .padding(.top, JP.Spacing.sm)
            }
            .padding(JP.Spacing.lg)
        }
        .background(JP.Color.pageBackground)
        .jpSaveConfirmation(isShowing: didSave)
    }

    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Consistency", icon: "circle.lefthalf.filled")
            JPMetric(value: "\(consistency)", unit: "of 7")
            Stepper("Consistency level", value: $consistency, in: 1...7)
                .labelsHidden()
                .font(JP.Font.body)
            Text(PouchConsistency.label(for: consistency))
                .font(JP.Font.calloutMedium)
                .foregroundStyle(JP.Color.primaryText)
            JPCaption("Loosely adapted from the Bristol Stool Scale. Pouch output tends to run looser than typical stool, so mid-range is a common baseline.")
        }
        .jpCard()
    }

    private var urgencySection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Urgency", icon: "timer")
            Toggle("Felt urgent", isOn: $hasUrgency)
                .toggleStyle(.jpCheckbox)
            if hasUrgency {
                Stepper("Severity \(urgencySeverity) of 5", value: $urgencySeverity, in: 0...5)
                    .font(JP.Font.body)
            }
        }
        .jpCard()
    }

    private var bloodSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Blood", icon: "drop.triangle")
            JPTagPicker(
                options: BloodLevel.allCases,
                title: \.displayName,
                tint: blood == .none ? JP.Color.accent : JP.Color.attention,
                selection: $blood
            )
        }
        .jpCard()
    }

    private var painSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Pain", icon: "bolt.heart")
            JPMetric(value: "\(pain)", unit: "of 5")
            Stepper("Pain level", value: $pain, in: 0...5)
                .labelsHidden()
                .font(JP.Font.body)
            Toggle("Nighttime episode", isOn: $isNight)
                .toggleStyle(.jpCheckbox)
        }
        .jpCard()
    }

    // Collapsed by default so the common case stays a two-tap save. Catching up on a missed
    // day matters: a day with nothing logged is a gap, and the pattern flags deliberately
    // break their streaks across gaps rather than guess.
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Time", icon: "clock")
            Toggle("This happened earlier", isOn: Binding(
                get: { isBackdating },
                set: { backdatedTo = $0 ? .now : nil }
            ))
            .toggleStyle(.jpCheckbox)

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
                .font(JP.Font.body)
            } else {
                JPCaption("Saves with the current time.")
            }
        }
        .jpCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Notes", icon: "square.and.pencil")
            JPTextField(
                label: "Anything worth remembering",
                placeholder: "Optional",
                axis: .vertical,
                text: $notes
            )
        }
        .jpCard()
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
            withAnimation { didSave = false }
        }
    }
}
