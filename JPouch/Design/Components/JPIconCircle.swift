import SwiftUI

/// A symbol in a tinted circle — quick actions, journey stages, section markers.
struct JPIconCircle: View {
    let systemImage: String
    var tint: Color = JP.Color.accent
    var size: CGFloat = 44
    var isFilled = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(isFilled ? Color.white : tint)
            .frame(width: size, height: size)
            .background(
                Circle().fill(isFilled ? tint : tint.opacity(0.12))
            )
            // Always decorative: every use sits beside a text label that says the same thing.
            .accessibilityHidden(true)
    }
}

/// The transient "Saved" badge shown after a log entry is written.
///
/// Every log form saves in place and stays open, so without this there's no signal a tap did
/// anything. It previously existed only on the output form, which made the other forms feel
/// broken by comparison.
struct JPSaveConfirmation: View {
    var text = "Saved"

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(JP.Font.captionMedium)
            .foregroundStyle(JP.Color.confirmation)
            .padding(.horizontal, JP.Spacing.md)
            .padding(.vertical, JP.Spacing.sm)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(JP.Color.confirmation.opacity(0.3)))
            .shadow(color: JP.Shadow.color, radius: JP.Shadow.radius, y: JP.Shadow.y)
            .padding(.top, JP.Spacing.sm)
    }
}

extension View {
    /// Overlays the save badge, sliding it in from the top edge.
    func jpSaveConfirmation(isShowing: Bool, text: String = "Saved") -> some View {
        overlay(alignment: .top) {
            if isShowing {
                JPSaveConfirmation(text: text)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
