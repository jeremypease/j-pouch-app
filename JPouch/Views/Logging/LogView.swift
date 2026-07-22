import SwiftUI

private enum LogKind: String, CaseIterable, Identifiable {
    case output = "Output"
    case hydration = "Hydration"
    case food = "Food"
    case medication = "Meds"
    var id: String { rawValue }
}

struct LogView: View {
    @State private var kind: LogKind = .output

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Log type", selection: $kind) {
                    ForEach(LogKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch kind {
                case .output: LogOutputForm()
                case .hydration: LogHydrationForm()
                case .food: LogFoodForm()
                case .medication: LogMedicationForm()
                }

                Spacer()
            }
            .navigationTitle("Log")
        }
    }
}
