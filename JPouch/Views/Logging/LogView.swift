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
            VStack(spacing: 0) {
                Picker("Log type", selection: $kind) {
                    ForEach(LogKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, JP.Spacing.lg)
                .padding(.vertical, JP.Spacing.md)
                .background(JP.Color.pageBackground)

                // No Spacer below: the output form scrolls and the rest are Forms, so each one
                // already fills the space it's given. A Spacer here collapsed them upward and
                // left the segmented control floating over a gap.
                switch kind {
                case .output: LogOutputForm()
                case .hydration: LogHydrationForm()
                case .food: LogFoodForm()
                case .medication: LogMedicationForm()
                }
            }
            .navigationTitle("Log")
        }
    }
}
