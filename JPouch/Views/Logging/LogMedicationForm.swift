import SwiftUI
import SwiftData

private struct ReminderTimeDraft: Identifiable {
    let id = UUID()
    var time: Date
}

struct LogMedicationForm: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var healthKit = HealthKitManager.shared
    @State private var healthMedications: [HealthMedication] = []

    @State private var name = ""
    @State private var dosage = ""
    @State private var schedule = ""
    @State private var isAntibiotic = false
    @State private var startDate = Date.now
    @State private var hasEndDate = false
    @State private var endDate = Date.now
    @State private var reminderEnabled = false
    @State private var reminderTimes: [ReminderTimeDraft] = []

    var body: some View {
        Form {
            if healthKit.supportsMedicationsAPI {
                Section {
                    if healthMedications.isEmpty {
                        Text("No medications found in Health, or access hasn't been granted yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Connect to Apple Health") {
                            Task {
                                await healthKit.requestMedicationsAuthorization()
                                healthMedications = (try? await healthKit.fetchMedications()) ?? []
                            }
                        }
                    }
                    ForEach(healthMedications) { medication in
                        VStack(alignment: .leading) {
                            Text(medication.nickname ?? medication.name)
                            if medication.hasSchedule {
                                Text("Scheduled in Health").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Open Health App to Add or Edit") {
                        openURL(URL(string: "x-apple-health://")!)
                    }
                } header: {
                    Text("Your Medications")
                } footer: {
                    Text("Medications are managed in the Health app. Reminders for anything scheduled there come from Health, not J-Pouch.")
                }
            }

            Section("Track a Course") {
                TextField("Name", text: $name)
                TextField("Dosage", text: $dosage)
                TextField("Schedule (e.g. twice daily)", text: $schedule)
            }
            Section("Antibiotic Course") {
                Toggle("This is an antibiotic course", isOn: $isAntibiotic)
                DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                Toggle("Has end date", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End date", selection: $endDate, displayedComponents: .date)
                }
            }
            Section {
                Toggle("Remind me to take this", isOn: $reminderEnabled)
                if reminderEnabled {
                    ForEach($reminderTimes) { $draft in
                        DatePicker(
                            "Reminder time",
                            selection: $draft.time,
                            displayedComponents: .hourAndMinute
                        )
                    }
                    .onDelete { reminderTimes.remove(atOffsets: $0) }
                    Button("Add Reminder Time") {
                        reminderTimes.append(ReminderTimeDraft(time: .now))
                    }
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("J-Pouch reminders for this course, separate from anything scheduled in Health.")
            }
            Section {
                Button {
                    save()
                } label: {
                    Text("Save Entry").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .listRowBackground(Color.clear)
        }
        .task {
            // A silent read, not a permission request — HKUserAnnotatedMedicationQuery always
            // re-prompts per Apple's docs, so we only trigger that from an explicit tap below.
            if healthKit.supportsMedicationsAPI {
                healthMedications = (try? await healthKit.fetchMedications()) ?? []
            }
        }
    }

    private func save() {
        let entry = MedicationEntry(
            name: name,
            dosage: dosage,
            schedule: schedule,
            isAntibiotic: isAntibiotic,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            reminderEnabled: reminderEnabled,
            reminderMinutesOfDay: reminderTimes.map { Self.minutesSinceMidnight($0.time) }
        )
        modelContext.insert(entry)
        Task {
            await NotificationManager.shared.requestAuthorizationIfNeeded()
            await NotificationManager.shared.scheduleReminders(for: entry)
        }
        name = ""
        dosage = ""
        schedule = ""
        isAntibiotic = false
        hasEndDate = false
        reminderEnabled = false
        reminderTimes = []
    }

    private static func minutesSinceMidnight(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
