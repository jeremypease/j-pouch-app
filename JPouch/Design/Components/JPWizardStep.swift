import SwiftUI

/// Capsule-dot progress for a multi-step flow (onboarding, the logging wizards).
///
/// Extracted out of `OnboardingView` so the logging wizards can share one implementation
/// instead of redrawing the same dots by hand.
struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: JP.Spacing.sm) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? JP.Color.brandFill : JP.Color.separator)
                    // The current step widens into a pill, as the design shows, so position is
                    // readable without counting dots.
                    .frame(width: index == current ? 22 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: current)
        // These are now the only progress signal, the step count text having gone, so they
        // carry it for VoiceOver rather than being hidden as decoration.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

/// A step's title + subtitle, above its fields.
struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            Text(title).jpDisplayMedium()
            Text(subtitle)
                .font(JP.Font.callout)
                .foregroundStyle(JP.Color.secondaryText)
        }
    }
}

/// Back/Next(-or-Save) footer for a step wizard, matching onboarding's button placement.
///
/// Onboarding itself is forward-only and doesn't need this — Back is new behavior specific to
/// the logging wizards, where a mis-tap needs to be correctable without abandoning the entry.
struct WizardFooter: View {
    var canGoBack: Bool
    var isLastStep: Bool
    var nextTitle: String = "Continue"
    var lastStepTitle: String = "Save entry"
    var back: () -> Void
    var next: () -> Void

    var body: some View {
        HStack(spacing: JP.Spacing.md) {
            if canGoBack {
                Button("Back", action: back)
                    .buttonStyle(.jpSecondary(fullWidth: false))
            }
            Button(isLastStep ? lastStepTitle : nextTitle, action: next)
                .buttonStyle(.jpPrimary)
        }
    }
}
