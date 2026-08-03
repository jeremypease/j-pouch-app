import SwiftUI

/// The design system's buttons.
///
/// `primary` is the filled brand action, `secondary` the outlined one, `quiet` a plain tappable
/// label. All three hold the 44pt minimum tap target even when their text is short, which the
/// stock `.bordered` style does not.
struct JPButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case quiet
    }

    var variant: Variant = .primary
    var fullWidth = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(JP.Font.calloutMedium)
            .foregroundStyle(foreground)
            .padding(.horizontal, JP.Spacing.lg)
            .padding(.vertical, JP.Spacing.md)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: JP.Layout.minimumTapTarget)
            .background {
                let shape = RoundedRectangle(cornerRadius: JP.Radius.control, style: .continuous)
                switch variant {
                case .primary:
                    shape.fill(JP.Color.brandFill)
                case .secondary:
                    shape
                        .fill(JP.Color.cardSurface)
                        .overlay(shape.strokeBorder(JP.Color.brandFill.opacity(0.5)))
                case .quiet:
                    Color.clear
                }
            }
            .opacity(isEnabled ? 1 : 0.4)
            // Scale rather than fade on press: at the low opacities a fade needs to be
            // noticeable, the label itself gets hard to read mid-tap.
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary:
            // White on the saturated brand teal, which is the one place teal-500 carries text —
            // and it clears AA in that direction.
            return .white
        case .secondary, .quiet:
            return JP.Color.accent
        }
    }
}

extension ButtonStyle where Self == JPButtonStyle {
    static var jpPrimary: JPButtonStyle { JPButtonStyle(variant: .primary) }
    static var jpSecondary: JPButtonStyle { JPButtonStyle(variant: .secondary) }
    static var jpQuiet: JPButtonStyle { JPButtonStyle(variant: .quiet, fullWidth: false) }

    static func jpPrimary(fullWidth: Bool) -> JPButtonStyle {
        JPButtonStyle(variant: .primary, fullWidth: fullWidth)
    }

    static func jpSecondary(fullWidth: Bool) -> JPButtonStyle {
        JPButtonStyle(variant: .secondary, fullWidth: fullWidth)
    }
}
