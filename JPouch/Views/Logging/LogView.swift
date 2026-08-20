import SwiftUI

private enum LogKind: String, CaseIterable, Identifiable {
    case output = "Output"
    case hydration = "Hydration"
    case food = "Food"
    case medication = "Meds"
    var id: String { rawValue }
}

struct LogView: View {
    let profile: UserProfile

    @State private var kind: LogKind = .output
    @State private var showingOutputWizard = false
    @State private var showingHydrationWizard = false

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

                // No Spacer below: the food/meds forms scroll and fill the space they're given,
                // and the launchers below center themselves — a Spacer here collapsed them
                // upward and left the segmented control floating over a gap.
                switch kind {
                case .output:
                    LogEntryLauncher(
                        title: "Log output",
                        subtitle: "Consistency, urgency, blood, and pain — a few steps, saved when you're done.",
                        icon: "circle.lefthalf.filled",
                        isPresented: $showingOutputWizard
                    )
                case .hydration:
                    LogEntryLauncher(
                        title: "Log hydration",
                        subtitle: "Type and amount, then when it happened.",
                        icon: "drop",
                        isPresented: $showingHydrationWizard
                    )
                case .food: LogFoodForm()
                case .medication: LogMedicationForm()
                }
            }
            .navigationTitle("Log")
        }
        .sheet(isPresented: $showingOutputWizard) {
            LogOutputWizard(profile: profile)
        }
        .sheet(isPresented: $showingHydrationWizard) {
            LogHydrationWizard()
        }
    }
}

/// The tab-level entry point for a wizard-style log — Output and Hydration no longer host their
/// forms in place, since a multi-step wizard animating under a static segmented control read
/// oddly. Tapping "Log entry" presents the wizard as a sheet instead.
private struct LogEntryLauncher: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: JP.Spacing.xl) {
            Spacer(minLength: JP.Spacing.xl)
            VStack(spacing: JP.Spacing.md) {
                JPIconCircle(systemImage: icon, tint: JP.Color.brandFill, size: 64)
                Text(title).jpDisplayMedium()
                Text(subtitle)
                    .font(JP.Font.callout)
                    .foregroundStyle(JP.Color.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, JP.Spacing.xl)
            Button("Log entry") { isPresented = true }
                .buttonStyle(.jpPrimary(fullWidth: false))
            Spacer(minLength: JP.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(JP.Color.pageBackground)
    }
}
