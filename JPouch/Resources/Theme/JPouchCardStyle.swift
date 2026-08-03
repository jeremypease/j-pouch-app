import SwiftUI

/// The dashboard card treatment from the design system: white surface, 20pt radius, a hairline
/// border, and a shallow shadow — replaces the ad hoc `.background(.thinMaterial, in:
/// RoundedRectangle(cornerRadius: 12))` used before this theme existed.
struct JPouchCard: ViewModifier {
    /// Set when the card represents a selectable option that's currently chosen (e.g. the
    /// onboarding stage picker) — swaps the hairline border for a heavier primary-colored one
    /// instead of relying on an icon alone to carry the selected state.
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(JPouchSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(JPouchColor.surface, in: RoundedRectangle(cornerRadius: JPouchRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: JPouchRadius.card)
                    .strokeBorder(selected ? JPouchColor.primary : JPouchColor.border, lineWidth: selected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

/// The pattern-flag treatment: coral/warning rather than red or orange — see
/// `JPouchColor.warning` for why. Used for "worth a conversation" signals, never for anything
/// framed as an emergency or a diagnosis.
struct JPouchFlagCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(JPouchSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(JPouchColor.warningSoft, in: RoundedRectangle(cornerRadius: JPouchRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: JPouchRadius.card)
                    .strokeBorder(JPouchColor.accentHover.opacity(0.4))
            )
    }
}

extension View {
    func jpouchCard(selected: Bool = false) -> some View {
        modifier(JPouchCard(selected: selected))
    }

    func jpouchFlagCard() -> some View {
        modifier(JPouchFlagCard())
    }
}
