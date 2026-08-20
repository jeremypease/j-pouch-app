import SwiftUI
import SwiftData

/// Steps through an Output (BM) entry rather than presenting every field on one screen —
/// replaces the old single-page `LogOutputForm`. Presented as a sheet from `LogView`, mirroring
/// `SymptomCheckInView`'s existing sheet-with-`NavigationStack` pattern.
struct LogOutputWizard: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private enum Step: Int, CaseIterable {
        case consistencyBlood, urgencyPain, timeNotes
    }

    @State private var step: Step = .consistencyBlood
    @State private var goingBack = false

    @State private var consistency = 4
    @State private var hasUrgency = false
    @State private var urgencySeverity = 2
    @State private var blood: BloodLevel = .none
    @State private var pain = 0
    @State private var isNight = false
    @State private var notes = ""
    /// nil means "whenever Save is tapped". Deliberately not a plain Date defaulting to now:
    /// a wizard left open for an hour would otherwise save the time it was opened.
    @State private var backdatedTo: Date?
    @State private var didSave = false

    private var isBackdating: Bool { backdatedTo != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: JP.Spacing.xl) {
                ScrollView {
                    Group {
                        switch step {
                        case .consistencyBlood: consistencyBloodStep
                        case .urgencyPain: urgencyPainStep
                        case .timeNotes: timeNotesStep
                        }
                    }
                    .padding(.top, JP.Spacing.lg)
                }

                StepIndicator(current: step.rawValue, total: Step.allCases.count)
                    .padding(.horizontal, JP.Spacing.lg)

                WizardFooter(
                    canGoBack: step != .consistencyBlood,
                    isLastStep: step == .timeNotes,
                    back: goBack,
                    next: advance
                )
                .padding(.horizontal, JP.Spacing.lg)
                .padding(.bottom, JP.Spacing.xl)
            }
            .background(JP.Color.pageBackground)
            .navigationTitle("Log output")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .jpSaveConfirmation(isShowing: didSave)
        }
    }

    // MARK: - Steps

    private var consistencyBloodStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.lg) {
            consistencySection
            bloodSection
        }
        .padding(.horizontal, JP.Spacing.lg)
        .id(Step.consistencyBlood)
        .transition(stepTransition)
    }

    private var urgencyPainStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.lg) {
            // Urgency doesn't apply without a sphincter involved — asking is noise at best and
            // alarming at worst for someone with an ostomy, so the block is skipped entirely
            // rather than shown and discarded.
            if !profile.hasOstomy {
                urgencySection
            }
            painSection
        }
        .padding(.horizontal, JP.Spacing.lg)
        .id(Step.urgencyPain)
        .transition(stepTransition)
    }

    private var timeNotesStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.lg) {
            timeSection
            notesSection
        }
        .padding(.horizontal, JP.Spacing.lg)
        .id(Step.timeNotes)
        .transition(stepTransition)
    }

    // MARK: - Fields

    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Consistency", icon: "circle.lefthalf.filled")
            JPMetric(value: "\(consistency)", unit: "of 7")
            // The visible figure lives in JPMetric above, so the Stepper's own label carries no
            // value. Without this, VoiceOver announces "Consistency level, adjustable" and the
            // current setting has to be hunted for elsewhere in the swipe order.
            Stepper("Consistency level", value: $consistency, in: 1...7)
                .labelsHidden()
                .font(JP.Font.body)
                .accessibilityValue("\(consistency) of 7, \(PouchConsistency.label(for: consistency))")
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
                .accessibilityValue("\(pain) of 5, \(PainLevel.summary(for: pain))")
            JPCaption(PainLevel.summary(for: pain))
            // Bag leakage/an overnight empty and pouch seepage aren't the same thing, so the
            // label changes rather than reusing "Nighttime episode" for both.
            Toggle(profile.hasOstomy ? "Bag leakage or overnight empty" : "Nighttime episode", isOn: $isNight)
                .toggleStyle(.jpCheckbox)
        }
        .jpCard()
    }

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

    // MARK: - Navigation

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingBack ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: goingBack ? .trailing : .leading).combined(with: .opacity)
        )
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            save()
            return
        }
        goingBack = false
        withAnimation(.easeInOut(duration: 0.25)) { step = next }
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        goingBack = true
        withAnimation(.easeInOut(duration: 0.25)) { step = previous }
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = OutputEntry(
            timestamp: backdatedTo ?? .now,
            consistency: consistency,
            // Ostomy users never see the urgency question, so nothing is asked-and-discarded —
            // it's simply never set.
            hasUrgency: profile.hasOstomy ? false : hasUrgency,
            urgencySeverity: (profile.hasOstomy || !hasUrgency) ? 0 : urgencySeverity,
            blood: blood,
            pain: pain,
            isNight: isNight,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(entry)

        withAnimation { didSave = true }
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            dismiss()
        }
    }
}

#Preview {
    LogOutputWizard(profile: UserProfile())
        .modelContainer(for: OutputEntry.self, inMemory: true)
}
