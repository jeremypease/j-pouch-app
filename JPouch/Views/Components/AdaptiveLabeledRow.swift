import SwiftUI

/// A label-and-value row that stacks vertically once text gets large.
///
/// `HStack { Text; Spacer; value }` is the natural way to write a settings row, but at
/// accessibility text sizes the Spacer has nothing to give and the value gets squeezed into a
/// few characters or truncated away entirely — precisely when someone needs to read it. This
/// keeps the familiar side-by-side layout at normal sizes and stacks when it stops fitting.
struct AdaptiveLabeledRow<Value: View>: View {
    let label: Text
    let value: Value

    init(label: String, @ViewBuilder value: () -> Value) {
        self.init(label: Text(label), value: value)
    }

    /// Takes a `Text` so a label that is itself a figure can carry the mono face on its numeric
    /// runs — "250 mL • Water" sets the amount in mono and the kind in the body face.
    init(label: Text, @ViewBuilder value: () -> Value) {
        self.label = label
        self.value = value()
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                label
                value
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                label
                Spacer()
                value
            }
        }
    }
}
