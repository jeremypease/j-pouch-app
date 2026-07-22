import SwiftUI
import SwiftData

struct LogMedicationForm: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var dosage = ""
    @State private var schedule = ""
    @State private var isAntibiotic = false
    @State private var startDate = Date.now
    @State private var hasEndDate = false
    @State private var endDate = Date.now

    var body: some View {
        Form {
            Section("Medication") {
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
    }

    private func save() {
        let entry = MedicationEntry(
            name: name,
            dosage: dosage,
            schedule: schedule,
            isAntibiotic: isAntibiotic,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil
        )
        modelContext.insert(entry)
        name = ""
        dosage = ""
        schedule = ""
        isAntibiotic = false
        hasEndDate = false
    }
}
