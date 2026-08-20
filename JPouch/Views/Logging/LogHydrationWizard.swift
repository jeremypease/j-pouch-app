import SwiftUI
import SwiftData

/// Steps through a Hydration entry rather than presenting everything on one screen — replaces
/// the old single-page `LogHydrationForm`. The old form's three quick-add buttons saved
/// immediately on tap; in a wizard, tapping an amount has to become *selection*, not action, so
/// they're now single-select chips plus a stepper for a custom amount, and saving happens on
/// the final Confirm step.
struct LogHydrationWizard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private enum Step: Int, CaseIterable {
        case typeAmount, time, confirm
    }

    private let presetAmountsML = [125, 250, 500]

    @State private var step: Step = .typeAmount
    @State private var goingBack = false

    @State private var kind: HydrationKind = .water
    @State private var volumeML = 250
    /// nil means "whenever Save is tapped" — same reasoning as the output wizard.
    @State private var backdatedTo: Date?
    @State private var syncError: String?
    @State private var didSave = false

    private var isBackdating: Bool { backdatedTo != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: JP.Spacing.xl) {
                ScrollView {
                    Group {
                        switch step {
                        case .typeAmount: typeAmountStep
                        case .time: timeStep
                        case .confirm: confirmStep
                        }
                    }
                    .padding(.top, JP.Spacing.lg)
                }

                StepIndicator(current: step.rawValue, total: Step.allCases.count)
                    .padding(.horizontal, JP.Spacing.lg)

                WizardFooter(
                    canGoBack: step != .typeAmount,
                    isLastStep: step == .confirm,
                    back: goBack,
                    next: advance
                )
                .padding(.horizontal, JP.Spacing.lg)
                .padding(.bottom, JP.Spacing.xl)
            }
            .background(JP.Color.pageBackground)
            .navigationTitle("Log hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .jpSaveConfirmation(isShowing: didSave, text: "\(volumeML) mL logged")
        }
    }

    // MARK: - Steps

    private var typeAmountStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.lg) {
            typeSection
            amountSection
        }
        .padding(.horizontal, JP.Spacing.lg)
        .id(Step.typeAmount)
        .transition(stepTransition)
    }

    private var timeStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.lg) {
            timeSection
        }
        .padding(.horizontal, JP.Spacing.lg)
        .id(Step.time)
        .transition(stepTransition)
    }

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.lg) {
            confirmSection
        }
        .padding(.horizontal, JP.Spacing.lg)
        .id(Step.confirm)
        .transition(stepTransition)
    }

    // MARK: - Fields

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Type", icon: "drop")
            Picker("Type", selection: $kind) {
                ForEach(HydrationKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)
        }
        .jpCard()
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Amount", icon: "gauge.with.dots.needle.50percent")
            JPMetric(value: "\(volumeML)", unit: "mL")

            JPFlowLayout(spacing: JP.Spacing.sm) {
                ForEach(presetAmountsML, id: \.self) { amount in
                    Button {
                        volumeML = amount
                    } label: {
                        JPTag(text: "\(amount) mL", isSelected: volumeML == amount)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(volumeML == amount ? [.isButton, .isSelected] : .isButton)
                }
            }

            Stepper("Custom amount", value: $volumeML, in: 25...2000, step: 25)
                .labelsHidden()
                .font(JP.Font.body)
                .accessibilityValue("\(volumeML) mL")
            JPCaption("Pick a preset above, or fine-tune with the stepper.")
        }
        .jpCard()
    }

    // Collapsed by default so the common case stays a quick step. Catching up on a missed day
    // matters for the same reason it does on the output wizard: gaps are meant to break the
    // pattern flags' streaks rather than be guessed at.
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

    private var confirmSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Confirm", icon: "checkmark.circle")
            VStack(alignment: .leading, spacing: JP.Spacing.xs) {
                Text("\(volumeML) mL of \(kind.displayName)")
                    .font(JP.Font.calloutMedium)
                    .foregroundStyle(JP.Color.primaryText)
                Text((backdatedTo ?? .now).formatted(date: .abbreviated, time: .shortened))
                    .font(JP.Font.caption)
                    .foregroundStyle(JP.Color.secondaryText)
            }
            if let syncError {
                JPCaption(syncError)
            }
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
        let timestamp = backdatedTo ?? .now
        let entry = HydrationEntry(timestamp: timestamp, volumeML: volumeML, kind: kind)
        modelContext.insert(entry)

        withAnimation { didSave = true }
        Task {
            if kind == .water {
                do {
                    let sampleID = try await HealthKitManager.shared.logWater(volumeML: volumeML, date: timestamp)
                    entry.healthKitSampleID = sampleID.uuidString
                } catch {
                    syncError = "Saved locally, but couldn't sync to Health: \(error.localizedDescription)"
                }
            }
            try? await Task.sleep(for: .seconds(1.0))
            dismiss()
        }
    }
}

#Preview {
    LogHydrationWizard()
        .modelContainer(for: HydrationEntry.self, inMemory: true)
}
