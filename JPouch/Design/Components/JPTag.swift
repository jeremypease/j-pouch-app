import SwiftUI

/// A small capsule label — stage names, severity levels, counts.
///
/// The selectable form is used for single-choice rows like symptom severity, where a segmented
/// control would truncate the labels at accessibility text sizes.
struct JPTag: View {
    let text: String
    var tint: Color = JP.Color.accent
    var isSelected = false

    var body: some View {
        Text(text)
            .font(JP.Font.label)
            .foregroundStyle(isSelected ? Color.white : tint)
            .padding(.horizontal, JP.Spacing.md)
            .padding(.vertical, JP.Spacing.sm)
            .background {
                let shape = RoundedRectangle(cornerRadius: JP.Radius.tag, style: .continuous)
                if isSelected {
                    shape.fill(tint)
                } else {
                    shape
                        .fill(tint.opacity(0.12))
                        .overlay(shape.strokeBorder(tint.opacity(0.3)))
                }
            }
    }
}

/// A row of mutually exclusive tags.
///
/// Wraps rather than scrolls, so nothing is hidden off-screen at large text sizes — which a
/// horizontal `ScrollView` would do silently.
struct JPTagPicker<Option: Hashable & Identifiable>: View {
    let options: [Option]
    let title: (Option) -> String
    var tint: Color = JP.Color.accent
    @Binding var selection: Option

    var body: some View {
        JPFlowLayout(spacing: JP.Spacing.sm) {
            ForEach(options) { option in
                Button {
                    selection = option
                } label: {
                    JPTag(text: title(option), tint: tint, isSelected: selection == option)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

/// Lays subviews out left to right, wrapping onto new lines as needed.
///
/// `HStack` would squeeze tags past legibility and a horizontal `ScrollView` would hide them;
/// at accessibility text sizes a single severity label can be most of the screen width, so
/// wrapping is the only layout that keeps every option reachable.
struct JPFlowLayout: Layout {
    var spacing: CGFloat = JP.Spacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
