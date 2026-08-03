import SwiftUI
import SwiftData

private struct MedicationDraft: Identifiable {
    let id = UUID()
    var name = ""
    var dosage = ""
    var schedule = ""
    var isAntibiotic = false
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum Step: Int, CaseIterable {
        case stage, medications, hydration
    }

    @State private var step: Step = .stage

    // Stage
    @State private var selectedStage: Stage = .adaptation
    @State private var knowsSurgeryDate = false
    @State private var surgeryDate = Date.now

    // Medications
    @State private var takingMedications = false
    @State private var healthKit = HealthKitManager.shared
    @State private var draftMedications: [MedicationDraft] = []

    // Hydration
    @State private var knowsWeight = false
    @State private var weightLb: Double = 150
    @State private var weightFromHealth = false
    @State private var hydrationTargetML = 2000
    @State private var hasCustomizedTarget = false
    @State private var isConnectingHealth = false
    @State private var weightLookupMessage: String?

    private var suggestedHydrationTargetML: Int {
        // Rough starting point, not a medical recommendation: ~15 mL per lb (~33 mL/kg,
        // a commonly cited general fluid guideline) plus a buffer for pouch fluid loss.
        let raw = Int(weightLb * 15) + 500
        return (raw / 250) * 250
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: JP.Spacing.xl) {
                StepIndicator(current: step.rawValue, total: Step.allCases.count)
                    .padding(.top, JP.Spacing.xl)
                    .padding(.horizontal, JP.Spacing.lg)

                ScrollView {
                    switch step {
                    case .stage: stageStep
                    case .medications: medicationsStep
                    case .hydration: hydrationStep
                    }
                }

                Button(step == .hydration ? "Finish" : "Continue") {
                    advance()
                }
                .buttonStyle(.jpPrimary)
                .padding(.horizontal, JP.Spacing.lg)
                .padding(.bottom, JP.Spacing.xl)
            }
            .background(JP.Color.pageBackground)
        }
    }

    // MARK: - Stage

    private var stageStep: some View {
        VStack(spacing: JP.Spacing.xl) {
            // At accessibility sizes the full-size header consumed most of the screen and
            // pushed every stage past the fold — including the one selected by default, so
            // there was no visible sign of what tapping Continue would choose. The cards
            // below each carry their own description, so the standfirst is the part to drop.
            VStack(spacing: JP.Spacing.sm) {
                Text("Welcome to J-Pouch")
                    .font(dynamicTypeSize.isAccessibilitySize ? JP.Font.title : JP.Font.displayLarge)
                    .multilineTextAlignment(.center)
                if !dynamicTypeSize.isAccessibilitySize {
                    Text("Tell us where you are in your journey so we only ask you about what's relevant right now.")
                        .font(JP.Font.callout)
                        .foregroundStyle(JP.Color.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: JP.Spacing.md) {
                ForEach(Stage.allCases) { stage in
                    Button {
                        selectedStage = stage
                    } label: {
                        StageOption(stage: stage, isSelected: selectedStage == stage)
                    }
                    .buttonStyle(.plain)
                    // Selection was conveyed only by the checkmark, so VoiceOver gave no way
                    // to tell which stage was chosen.
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(selectedStage == stage ? [.isButton, .isSelected] : .isButton)
                }
            }

            // Without a date there is nothing for the app to derive from, so it would be stuck
            // on whatever was picked here until the person went looking in Settings.
            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                Toggle("I know my \(selectedStage.promptedDateLabel.lowercased())", isOn: $knowsSurgeryDate)
                    .font(JP.Font.callout)
                if knowsSurgeryDate {
                    DatePicker(
                        selectedStage.promptedDateLabel,
                        selection: $surgeryDate,
                        displayedComponents: .date
                    )
                    .font(JP.Font.callout)
                }
                JPCaption("Optional, but it lets J-Pouch move you between stages on its own instead of waiting for you to update it.")
            }
            .jpCard()
        }
        .padding(.horizontal, JP.Spacing.lg)
    }

    private var stagedSurgeryDateValue: Date? {
        guard knowsSurgeryDate, selectedStage.promptedDate == .stagedSurgery else { return nil }
        return surgeryDate
    }

    private var takedownDateValue: Date? {
        guard knowsSurgeryDate, selectedStage.promptedDate == .takedown else { return nil }
        return surgeryDate
    }

    // MARK: - Medications

    private var medicationsStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.xl) {
            StepHeader(
                title: "Medications",
                subtitle: "Are you currently taking any medications?"
            )

            Picker("Taking medications", selection: $takingMedications) {
                Text("No").tag(false)
                Text("Yes").tag(true)
            }
            .pickerStyle(.segmented)

            if takingMedications {
                if healthKit.supportsMedicationsAPI {
                    VStack(alignment: .leading, spacing: JP.Spacing.md) {
                        JPCaption("Add them in the Health app under Browse → Medications — J-Pouch will show them automatically once you connect Health on the next step, so you don't need to re-enter anything. You'll get a separate prompt there for picking which medications to share, so watch for two prompts, not one.")
                        Button("Open Health App") {
                            openURL(URL(string: "x-apple-health://")!)
                        }
                        .buttonStyle(.jpSecondary)
                    }
                    .jpCard()
                } else {
                    VStack(alignment: .leading, spacing: JP.Spacing.lg) {
                        ForEach($draftMedications) { $draft in
                            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                                JPTextField(label: "Name", placeholder: "e.g. Ciprofloxacin", text: $draft.name)
                                JPTextField(label: "Dosage", placeholder: "e.g. 500 mg", text: $draft.dosage)
                                JPTextField(label: "Schedule", placeholder: "e.g. twice daily", text: $draft.schedule)
                                Toggle("Antibiotic course", isOn: $draft.isAntibiotic)
                                    .toggleStyle(.jpCheckbox)
                            }
                            .jpCard()
                        }
                        Button("Add Medication") {
                            draftMedications.append(MedicationDraft())
                        }
                        .buttonStyle(.jpSecondary)
                    }
                    .onAppear {
                        if draftMedications.isEmpty {
                            draftMedications.append(MedicationDraft())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, JP.Spacing.lg)
    }

    // MARK: - Hydration

    private var hydrationStep: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.xl) {
            StepHeader(
                title: "Hydration Target",
                subtitle: "Pouch patients often need more fluid than average. Connect Apple Health and we'll suggest a starting point from your weight\(healthKit.supportsMedicationsAPI ? " — this also lets J-Pouch show medications from Health" : "") — you can always adjust it later in Settings."
            )

            healthConnectCard

            if let weightLookupMessage {
                JPCaption(weightLookupMessage)
            }

            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                Toggle("I'll enter my weight", isOn: $knowsWeight)
                    .toggleStyle(.jpCheckbox)

                if knowsWeight {
                    Stepper("Weight: \(Int(weightLb)) lb", value: $weightLb, in: 60...400, step: 1)
                        .font(JP.Font.body)
                    if weightFromHealth {
                        JPCaption("From Health — adjust if this isn't current.")
                    }
                    if !hasCustomizedTarget {
                        JPCaption("Suggested target: \(suggestedHydrationTargetML) mL/day")
                    }
                }
            }
            .jpCard()

            VStack(alignment: .leading, spacing: JP.Spacing.md) {
                JPCardHeader(title: "Daily target", icon: "drop.fill")
                JPMetric(value: "\(hydrationTargetML)", unit: "mL/day")
                Stepper(
                    "Daily target",
                    value: $hydrationTargetML,
                    in: 500...5000,
                    step: 250
                )
                .labelsHidden()
                .font(JP.Font.body)
                JPCaption("This is a starting point, not medical advice — talk to your GI or dietitian for a number tailored to you, especially with high output.")
            }
            .jpCard()
        }
        .padding(.horizontal, JP.Spacing.lg)
        .onChange(of: weightLb) {
            if !hasCustomizedTarget {
                hydrationTargetML = suggestedHydrationTargetML
            }
        }
        .onChange(of: hydrationTargetML) {
            if hydrationTargetML != suggestedHydrationTargetML {
                hasCustomizedTarget = true
            }
        }
        .task {
            await healthKit.refreshConnectionState()
        }
    }

    /// The Apple Health sub-step, given its own card so connecting reads as a distinct action
    /// rather than one more control in a stack.
    @ViewBuilder
    private var healthConnectCard: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            HStack(spacing: JP.Spacing.md) {
                JPIconCircle(systemImage: "heart.fill", tint: JP.Color.critical)
                VStack(alignment: .leading, spacing: JP.Spacing.xs) {
                    Text("Apple Health")
                        .font(JP.Font.headline)
                    if healthKit.connectionState == .connected {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .font(JP.Font.caption)
                            .foregroundStyle(JP.Color.confirmation)
                    }
                }
                Spacer(minLength: 0)
            }

            if healthKit.connectionState == .connected {
                // Connecting and reading the weight can fail independently, so being
                // connected must not be a dead end when the value didn't come through.
                if !weightFromHealth {
                    Button {
                        Task { await loadWeightFromHealth() }
                    } label: {
                        if isConnectingHealth {
                            ProgressView()
                        } else {
                            Text("Use My Weight from Health")
                        }
                    }
                    .buttonStyle(.jpSecondary)
                    .disabled(isConnectingHealth)
                }
            } else if healthKit.connectionState == .unavailable {
                JPCaption("Apple Health isn't available on this device.")
            } else {
                // Covers .unknown as well as .notConnected. Unlike Settings, showing the
                // button before the check completes is the right default here: this is
                // first run, so almost nobody is connected yet, and the button is the
                // actionable choice either way.
                Button {
                    connectToHealth()
                } label: {
                    if isConnectingHealth {
                        ProgressView()
                    } else {
                        Text("Connect to Apple Health")
                    }
                }
                .buttonStyle(.jpSecondary)
                .disabled(isConnectingHealth)
            }
        }
        .jpCard()
    }

    private func connectToHealth() {
        isConnectingHealth = true
        Task {
            await healthKit.requestAuthorization()

            // Read the weight before asking about medications. That request presents its own
            // per-object sheet, and on iOS 26 the read grant is itself a two-sheet flow
            // (access, then how much history to share) — querying while sheets are still
            // coming and going returned nothing. Taking the value first, while we know the
            // read grant just settled, is both more reliable and better ordered.
            await loadWeightFromHealth()

            if healthKit.supportsMedicationsAPI {
                await healthKit.requestMedicationsAuthorization()
            }
            isConnectingHealth = false
        }
    }

    private func loadWeightFromHealth() async {
        isConnectingHealth = true
        defer { isConnectingHealth = false }
        do {
            guard let kg = try await healthKit.latestBodyMassKG() else {
                weightLookupMessage = "No weight found in Health — enter yours below."
                return
            }
            weightLb = (kg * 2.20462).rounded()
            weightFromHealth = true
            knowsWeight = true
            weightLookupMessage = nil
        } catch {
            // Distinct from having no data: a failed read is retryable, and telling someone
            // their weight isn't in Health when the query simply failed sends them off to
            // check the wrong thing.
            weightLookupMessage = "Couldn't read your weight from Health just now. Tap to try again, or enter it below."
        }
    }

    // MARK: - Navigation

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            finishOnboarding()
            return
        }
        step = next
    }

    private func finishOnboarding() {
        let profile = UserProfile(
            manualStage: Stage.override(
                forPicked: selectedStage,
                stagedSurgeryDate: stagedSurgeryDateValue,
                takedownDate: takedownDateValue
            ),
            stagedSurgeryDate: stagedSurgeryDateValue,
            takedownDate: takedownDateValue,
            dailyHydrationTargetML: hydrationTargetML
        )
        modelContext.insert(profile)

        if takingMedications {
            for draft in draftMedications where !draft.name.trimmingCharacters(in: .whitespaces).isEmpty {
                let entry = MedicationEntry(
                    name: draft.name,
                    dosage: draft.dosage,
                    schedule: draft.schedule,
                    isAntibiotic: draft.isAntibiotic
                )
                modelContext.insert(entry)
            }
        }
    }
}

// MARK: - Pieces

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            Text("Step \(current + 1) of \(total)")
                .font(JP.Font.label)
                .foregroundStyle(JP.Color.secondaryText)
            HStack(spacing: JP.Spacing.xs) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index <= current ? JP.Color.brandFill : JP.Color.separator)
                        .frame(height: 4)
                }
            }
            // The text above says the same thing, and four capsules read as noise in VoiceOver.
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            Text(title).font(JP.Font.displayMedium)
            Text(subtitle)
                .font(JP.Font.callout)
                .foregroundStyle(JP.Color.secondaryText)
        }
    }
}

private struct StageOption: View {
    let stage: Stage
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: JP.Spacing.md) {
            VStack(alignment: .leading, spacing: JP.Spacing.xs) {
                Text(stage.displayName)
                    .font(JP.Font.headline)
                    .foregroundStyle(JP.Color.primaryText)
                Text(stage.summary)
                    .font(JP.Font.caption)
                    .foregroundStyle(JP.Color.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(JP.Color.brandFill)
                    // The trait on the button already conveys this; without hiding it
                    // VoiceOver reads a redundant "checkmark circle fill".
                    .accessibilityHidden(true)
            }
        }
        .jpCard(tint: isSelected ? JP.Color.brandFill : nil)
    }
}

#Preview {
    OnboardingView()
}
