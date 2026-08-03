import SwiftUI

/// A checkbox rather than a switch, for multi-select lists like symptom types.
///
/// A column of iOS switches reads as a settings screen — a list of things being turned on
/// permanently — which is the wrong idea for "which of these did you feel today". Checkboxes
/// read as a form you fill in and move on from.
struct JPCheckboxToggleStyle: ToggleStyle {
    var tint: Color = JP.Color.accent

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: JP.Spacing.md) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(configuration.isOn ? tint : JP.Color.secondaryText)
                    // The trait below already conveys checked state; without this VoiceOver
                    // reads a redundant "checkmark square fill".
                    .accessibilityHidden(true)

                configuration.label
                    .font(JP.Font.body)
                    .foregroundStyle(JP.Color.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .frame(minHeight: JP.Layout.minimumTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(configuration.isOn ? [.isButton, .isSelected] : .isButton)
    }
}

extension ToggleStyle where Self == JPCheckboxToggleStyle {
    static var jpCheckbox: JPCheckboxToggleStyle { JPCheckboxToggleStyle() }
}
