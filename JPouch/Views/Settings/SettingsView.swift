import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @State private var healthKit = HealthKitManager.shared

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
                Section("Timeline") {
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
                }
                Section("Hydration") {
                    Stepper(
                        "Daily target: \(profile.dailyHydrationTargetML) mL",
                        value: $profile.dailyHydrationTargetML,
                        in: 500...5000,
                        step: 250
                    )
                }
                Section("Apple Health") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(healthKit.isAuthorized ? "Connected" : "Not connected")
                            .foregroundStyle(.secondary)
                    }
                    Button("Connect to Apple Health") {
                        Task { await healthKit.requestAuthorization() }
                    }
                }
                Section {
                    Text("J-Pouch tracks patterns to help you spot trends — it doesn't diagnose. Always bring concerns to your GI.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
