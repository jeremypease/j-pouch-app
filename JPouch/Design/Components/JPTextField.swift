import SwiftUI

/// A labelled text input on the design system's surfaces.
///
/// Used on the custom screens (symptom check-in, onboarding) where there's no `Form` to supply
/// chrome. Screens that still use a native `Form` keep the system field — mixing the two inside
/// one `Form` section looks like a bug rather than a design.
struct JPTextField: View {
    let label: String
    var placeholder: String = ""
    var axis: Axis = .horizontal
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            Text(label)
                .font(JP.Font.label)
                .foregroundStyle(JP.Color.secondaryText)

            TextField(placeholder, text: $text, axis: axis)
                .font(JP.Font.body)
                .padding(.horizontal, JP.Spacing.md)
                .padding(.vertical, JP.Spacing.md)
                .frame(minHeight: JP.Layout.minimumTapTarget, alignment: .topLeading)
                .background {
                    let shape = RoundedRectangle(cornerRadius: JP.Radius.control, style: .continuous)
                    shape
                        .fill(JP.Color.inputSurface)
                        .overlay(shape.strokeBorder(JP.Color.separator))
                }
        }
    }
}
