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

    private enum Step: Int, CaseIterable {
        case stage, medications, hydration
    }

    @State private var step: Step = .stage

    // Stage
    @State private var selectedStage: Stage = .adaptation

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
    @State private var didAttemptHealthConnect = false

    private var suggestedHydrationTargetML: Int {
        // Rough starting point, not a medical recommendation: ~15 mL per lb (~33 mL/kg,
        // a commonly cited general fluid guideline) plus a buffer for pouch fluid loss.
        let raw = Int(weightLb * 15) + 500
        return (raw / 250) * 250
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 24)

                ScrollView {
                    switch step {
                    case .stage: stageStep
                    case .medications: medicationsStep
                    case .hydration: hydrationStep
                    }
                }

                Button {
                    advance()
                } label: {
                    Text(step == .hydration ? "Finish" : "Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Stage

    private var stageStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Welcome to J-Pouch")
                    .font(.largeTitle.bold())
                Text("Tell us where you are in your journey so we only ask you about what's relevant right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(Stage.allCases) { stage in
                    Button {
                        selectedStage = stage
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stage.displayName)
                                    .font(.headline)
                                Text(stage.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if selectedStage == stage {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Medications

    private var medicationsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Medications")
                    .font(.title2.bold())
                Text("Are you currently taking any medications?")
                    .foregroundStyle(.secondary)
            }

            Picker("Taking medications", selection: $takingMedications) {
                Text("No").tag(false)
                Text("Yes").tag(true)
            }
            .pickerStyle(.segmented)

            if takingMedications {
                if healthKit.supportsMedicationsAPI {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add them in the Health app — J-Pouch will show them here automatically once you connect Health on the next step. You don't need to re-enter anything.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Open Health App") {
                            openURL(URL(string: "x-apple-health://")!)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach($draftMedications) { $draft in
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Name", text: $draft.name)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Dosage", text: $draft.dosage)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Schedule (e.g. twice daily)", text: $draft.schedule)
                                    .textFieldStyle(.roundedBorder)
                                Toggle("Antibiotic course", isOn: $draft.isAntibiotic)
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Button("Add Medication") {
                            draftMedications.append(MedicationDraft())
                        }
                        .buttonStyle(.bordered)
                    }
                    .onAppear {
                        if draftMedications.isEmpty {
                            draftMedications.append(MedicationDraft())
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Hydration

    private var hydrationStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hydration Target")
                    .font(.title2.bold())
                Text("Pouch patients often need more fluid than average. Connect Apple Health and we'll suggest a starting point from your weight\(healthKit.supportsMedicationsAPI ? " — this also lets J-Pouch show medications from Health" : "") — you can always adjust it later in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if healthKit.isAuthorized {
                Label("Connected to Apple Health", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            } else {
                Button {
                    connectToHealth()
                } label: {
                    if isConnectingHealth {
                        ProgressView()
                    } else {
                        Text("Connect to Apple Health")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isConnectingHealth)
            }

            if didAttemptHealthConnect && !weightFromHealth {
                Text("No weight found in Health — enter yours below.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Toggle("I'll enter my weight", isOn: $knowsWeight)

            if knowsWeight {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper("Weight: \(Int(weightLb)) lb", value: $weightLb, in: 60...400, step: 1)
                    if weightFromHealth {
                        Text("From Health — adjust if this isn't current.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !hasCustomizedTarget {
                        Text("Suggested target: \(suggestedHydrationTargetML) mL/day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Stepper(
                    "Daily target: \(hydrationTargetML) mL",
                    value: $hydrationTargetML,
                    in: 500...5000,
                    step: 250
                )
                Text("This is a starting point, not medical advice — talk to your GI or dietitian for a number tailored to you, especially with high output.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
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
    }

    private func connectToHealth() {
        isConnectingHealth = true
        Task {
            await healthKit.requestAuthorization()
            if healthKit.supportsMedicationsAPI {
                await healthKit.requestMedicationsAuthorization()
            }
            if let kg = try? await healthKit.latestBodyMassKG() {
                weightLb = (kg * 2.20462).rounded()
                weightFromHealth = true
                knowsWeight = true
            }
            didAttemptHealthConnect = true
            isConnectingHealth = false
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
        let profile = UserProfile(stage: selectedStage, dailyHydrationTargetML: hydrationTargetML)
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

#Preview {
    OnboardingView()
}
