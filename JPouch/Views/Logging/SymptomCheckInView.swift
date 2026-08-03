import SwiftUI
import SwiftData

/// A standalone symptom check-in, reached from Home rather than buried in the Log tab.
///
/// Built on the design system's surfaces rather than a native `Form`: this is a short,
/// deliberate sit-down entry, and the tag/checkbox treatment keeps every option legible at
/// accessibility text sizes, where a segmented control truncates "Skin irritation" to nothing.
struct SymptomCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var severity: SymptomSeverity = .mild
    @State private var selectedTypes: Set<SymptomType> = []
    @State private var location: SymptomLocation = .unspecified
    @State private var notes = ""
    /// nil means "whenever Save is tapped" — the same reasoning as the output form: a screen
    /// left open for an hour shouldn't save the time it was opened.
    @State private var backdatedTo: Date?
    @State private var didSave = false

    private var isBackdating: Bool { backdatedTo != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: JP.Spacing.xl) {
                    severitySection
                    symptomsSection
                    locationSection
                    notesSection
                    timeSection

                    Button("Save Check-In") { save() }
                        .buttonStyle(.jpPrimary)
                        .padding(.top, JP.Spacing.sm)
                }
                .padding(JP.Spacing.lg)
            }
            .background(JP.Color.pageBackground)
            .navigationTitle("Symptom Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .jpSaveConfirmation(isShowing: didSave)
        }
    }

    private var severitySection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "How bad is it?", icon: "gauge.with.dots.needle.33percent")
            JPTagPicker(
                options: SymptomSeverity.allCases,
                title: \.displayName,
                selection: $severity
            )
            JPCaption(severity.summary)
        }
        .jpCard()
    }

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            JPCardHeader(title: "What are you feeling?", icon: "list.bullet")
            JPCaption("Pick as many as apply, or none if you just want to note how the day went.")
                .padding(.bottom, JP.Spacing.xs)

            ForEach(SymptomType.allCases) { type in
                Toggle(type.displayName, isOn: binding(for: type))
                    .toggleStyle(.jpCheckbox)
            }
        }
        .jpCard()
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Where?", icon: "figure")
            JPTagPicker(
                options: SymptomLocation.allCases,
                title: \.displayName,
                selection: $location
            )
        }
        .jpCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Notes", icon: "square.and.pencil")
            JPTextField(
                label: "Anything worth remembering",
                placeholder: "Started after lunch, eased off by evening…",
                axis: .vertical,
                text: $notes
            )
        }
        .jpCard()
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: "Time", icon: "clock")
            Toggle("This happened earlier", isOn: Binding(
                get: { isBackdating },
                set: { backdatedTo = $0 ? .now : nil }
            ))
            .font(JP.Font.body)

            if let backdatedTo {
                DatePicker(
                    "When",
                    selection: Binding(
                        get: { backdatedTo },
                        set: { self.backdatedTo = $0 }
                    ),
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(JP.Font.body)
            } else {
                JPCaption("Saves with the current time.")
            }
        }
        .jpCard()
    }

    private func binding(for type: SymptomType) -> Binding<Bool> {
        Binding(
            get: { selectedTypes.contains(type) },
            set: { isOn in
                if isOn {
                    selectedTypes.insert(type)
                } else {
                    selectedTypes.remove(type)
                }
            }
        )
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = SymptomEntry(
            timestamp: backdatedTo ?? .now,
            severity: severity,
            // Sorted by the enum's own order so two check-ins with the same symptoms read the
            // same way in a list, rather than in whatever order they happened to be tapped.
            types: SymptomType.allCases.filter(selectedTypes.contains),
            location: location,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(entry)

        withAnimation { didSave = true }
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            dismiss()
        }
    }
}

#Preview {
    SymptomCheckInView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}
