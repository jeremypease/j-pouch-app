import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @State private var healthKit = HealthKitManager.shared
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    /// Permissions are changed outside the app, in Health, so the copy has to be clear that
    /// this screen can't turn them off — and honest that iOS hides read grants from us.
    private var healthFooter: String {
        let medications = healthKit.supportsMedicationsAPI
            ? " Medication sharing is a separate permission — manage it under Log → Meds."
            : ""
        switch healthKit.connectionState {
        case .unknown:
            return ""
        case .unavailable:
            return "Health data isn't available on this device."
        case .notConnected:
            return "J-Pouch can read your weight to suggest a hydration target, and save the water you log back to Health.\(medications)"
        case .connected:
            return "Apple doesn't let apps see which reading permissions you granted, or switch them off from here. To change or revoke what J-Pouch can see, open Health → Profile → Apps → J-Pouch.\(medications)"
        }
    }

    private var stageOverrideBinding: Binding<Stage?> {
        Binding(
            get: { profile.manualStageOverride },
            set: { profile.manualStageOverride = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Current stage", selection: stageOverrideBinding) {
                        Text("Automatic (from dates)").tag(Stage?.none)
                        ForEach(Stage.allCases) { stage in
                            Text(stage.displayName).tag(Stage?.some(stage))
                        }
                    }
                    if profile.manualStageOverride == nil {
                        LabeledContent("Computed stage", value: profile.stage.displayName)
                    }
                } header: {
                    Text("Stage")
                } footer: {
                    Text("Automatic moves you through stages on its own using the dates below. Pick a stage directly to override it.")
                }
                Section {
                    Toggle("Staged surgery date known", isOn: Binding(
                        get: { profile.stagedSurgeryDate != nil },
                        set: { profile.stagedSurgeryDate = $0 ? (profile.stagedSurgeryDate ?? .now) : nil }
                    ))
                    if profile.stagedSurgeryDate != nil {
                        DatePicker(
                            "Staged surgery date",
                            selection: Binding(
                                get: { profile.stagedSurgeryDate ?? .now },
                                set: { profile.stagedSurgeryDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                    Toggle("Takedown date known", isOn: Binding(
                        get: { profile.takedownDate != nil },
                        set: { profile.takedownDate = $0 ? (profile.takedownDate ?? .now) : nil }
                    ))
                    if profile.takedownDate != nil {
                        DatePicker(
                            "Takedown date",
                            selection: Binding(
                                get: { profile.takedownDate ?? .now },
                                set: { profile.takedownDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Timeline")
                } footer: {
                    Text("Takedown is the surgery that closes your temporary ileostomy and reconnects you through the pouch — it's when adaptation actually begins.")
                }
                Section("Hydration") {
                    Stepper(
                        "Daily target: \(profile.dailyHydrationTargetML) mL",
                        value: $profile.dailyHydrationTargetML,
                        in: 500...5000,
                        step: 250
                    )
                }
                Section {
                    LabeledContent("Status") {
                        switch healthKit.connectionState {
                        case .unknown:
                            Text("Checking…").foregroundStyle(.secondary)
                        case .unavailable:
                            Text("Unavailable").foregroundStyle(.secondary)
                        case .notConnected:
                            Text("Not connected").foregroundStyle(.secondary)
                        case .connected:
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    switch healthKit.connectionState {
                    case .connected:
                        LabeledContent("Saving water to Health", value: healthKit.canWriteWater ? "On" : "Off")
                        Button("Manage in Health App") {
                            openURL(URL(string: "x-apple-health://")!)
                        }
                    case .notConnected:
                        Button("Connect to Apple Health") {
                            Task {
                                await healthKit.requestAuthorization()
                                if healthKit.supportsMedicationsAPI {
                                    await healthKit.requestMedicationsAuthorization()
                                }
                            }
                        }
                    case .unknown, .unavailable:
                        EmptyView()
                    }
                } header: {
                    Text("Apple Health")
                } footer: {
                    Text(healthFooter)
                }
                Section {
                    Text("J-Pouch tracks patterns to help you spot trends — it doesn't diagnose. Always bring concerns to your GI.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .task {
                await healthKit.refreshConnectionState()
            }
            .onChange(of: scenePhase) { _, phase in
                // Permissions can be changed in the Health app while we're backgrounded,
                // so re-check rather than showing whatever was true when we last appeared.
                guard phase == .active else { return }
                Task { await healthKit.refreshConnectionState() }
            }
        }
    }
}
