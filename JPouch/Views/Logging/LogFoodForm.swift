import SwiftUI
import SwiftData

struct LogFoodForm: View {
    @Environment(\.modelContext) private var modelContext

    @State private var foodDescription = ""
    @State private var notes = ""

    var body: some View {
        Form {
            Section("What did you eat?") {
                TextField("e.g. Grilled chicken, rice, no dairy", text: $foodDescription, axis: .vertical)
            }
            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
            }
            Section {
                Button {
                    save()
                } label: {
                    Text("Save entry").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(foodDescription.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .listRowBackground(Color.clear)
        }
    }

    private func save() {
        let entry = FoodEntry(
            foodDescription: foodDescription,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(entry)
        foodDescription = ""
        notes = ""
    }
}
