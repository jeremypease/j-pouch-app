import SwiftUI

/// A label-and-value row that stacks vertically once text gets large.
///
/// `HStack { Text; Spacer; value }` is the natural way to write a settings row, but at
/// accessibility text sizes the Spacer has nothing to give and the value gets squeezed into a
/// few characters or truncated away entirely — precisely when someone needs to read it. This
/// keeps the familiar side-by-side layout at normal sizes and stacks when it stops fitting.
struct AdaptiveLabeledRow<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                value
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                Text(label)
                Spacer()
                value
            }
        }
    }
}
