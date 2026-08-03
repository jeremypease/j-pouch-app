import SwiftUI

extension View {
    /// The standard raised container.
    ///
    /// Pass a `tint` for cards carrying a status — it fills with a wash of that colour and draws
    /// a matching border, which is how pattern flags separate themselves from everyday cards
    /// without shouting. Before this existed the same recipe was written by hand in eight
    /// places, and two of them had already drifted.
    func jpCard(tint: Color? = nil, padding: CGFloat = JP.Spacing.lg) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: JP.Radius.card, style: .continuous)
                if let tint {
                    shape
                        .fill(tint.opacity(0.12))
                        .overlay(shape.strokeBorder(tint.opacity(0.35)))
                } else {
                    shape
                        .fill(JP.Color.cardSurface)
                        .shadow(color: JP.Shadow.color, radius: JP.Shadow.radius, y: JP.Shadow.y)
                }
            }
    }
}

/// A card's title row. The icon is decorative — the words carry the meaning, so it's hidden
/// from VoiceOver rather than announced as "waveform path ecg".
struct JPCardHeader: View {
    let title: String
    var icon: String?
    var tint: Color?

    var body: some View {
        Group {
            if let icon {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: icon).accessibilityHidden(true)
                }
            } else {
                Text(title)
            }
        }
        .font(JP.Font.headline)
        .foregroundStyle(tint ?? JP.Color.primaryText)
    }
}

/// Supporting text inside a card.
struct JPCaption: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(JP.Font.caption)
            .foregroundStyle(JP.Color.secondaryText)
    }
}

/// The large figure on a metric card.
struct JPMetric: View {
    let value: String
    var unit: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: JP.Spacing.xs) {
            Text(value).font(JP.Font.metric)
            if let unit {
                Text(unit)
                    .font(JP.Font.metricSmall)
                    .foregroundStyle(JP.Color.secondaryText)
            }
        }
    }
}

/// A thicker, rounder progress bar than the system hairline.
///
/// The system bar is 4pt and easy to miss at a glance, which is the opposite of what a daily
/// hydration target needs. The value is always spelled out in text beside it, so this is
/// decorative as far as VoiceOver is concerned.
struct JPProgressBar: View {
    let progress: Double
    var tint: Color = JP.Color.brandFill

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.18))
                Capsule()
                    .fill(tint)
                    .frame(width: geometry.size.width * clamped)
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}
