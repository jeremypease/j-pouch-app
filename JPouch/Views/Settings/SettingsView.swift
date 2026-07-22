import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @State private var healthKit = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Stage") {
                    Picker("Current stage", selection: $profile.stage) {
                        ForEach(Stage.allCases) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }
                }
                Section("Timeline") {
                    DatePicker(
                        "Staged surgery date",
                        selection: Binding(
                            get: { profile.stagedSurgeryDate ?? .now },
                            set: { profile.stagedSurgeryDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Takedown date",
                        selection: Binding(
                            get: { profile.takedownDate ?? .now },
                            set: { profile.takedownDate = $0 }
                        ),
                        displayedComponents: .date
                    )
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
