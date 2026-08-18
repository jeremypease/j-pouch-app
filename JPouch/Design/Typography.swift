import SwiftUI
import UIKit

/// Three faces, each with a job: Manrope for headings, IBM Plex Sans for reading, IBM Plex Mono
/// for figures.
///
/// Every style is declared with `relativeTo:`, so custom fonts still scale with Dynamic Type.
/// Without that, bundling fonts would silently break text sizing for the people most likely to
/// have turned it up — which for this app is a lot of them.
extension JP {
    enum Font {
        /// PostScript names, which are what `Font.custom` matches on — *not* file names.
        ///
        /// IBM ships abbreviated ones ("Medm", "SmBld") and the regular weights carry no suffix
        /// at all. These were read out of the shipped files' name tables rather than guessed;
        /// a wrong name here fails silently by falling back to the system font.
        private enum Face {
            /// The copy of Manrope-ExtraBold previously bundled reported itself as
            /// "ManropeExtraLight-ExtraBold" — a mangled name from Google's variable-font
            /// slicing. Nothing referenced it, so it registered and sat unused while the spec
            /// asked for extrabold headings. Replaced with a build whose name matches.
            static let displayHeavy = "Manrope-ExtraBold"
            static let display = "Manrope-Bold"
            static let displayMedium = "Manrope-SemiBold"
            static let heading = "Manrope-SemiBold"
            static let headingMedium = "Manrope-Medium"

            static let body = "IBMPlexSans"
            static let bodyMedium = "IBMPlexSans-Medm"
            static let bodySemibold = "IBMPlexSans-SmBld"

            static let mono = "IBMPlexMono"
            static let monoMedium = "IBMPlexMono-Medm"
        }

        // Headings — Manrope
        // Extrabold for the largest heading, per "headings use --weight-extrabold/--weight-bold".
        static let displayLarge = SwiftUI.Font.custom(Face.displayHeavy, size: 28, relativeTo: .largeTitle)
        static let displayMedium = SwiftUI.Font.custom(Face.display, size: 22, relativeTo: .title2)
        static let title = SwiftUI.Font.custom(Face.heading, size: 18, relativeTo: .title3)
        static let headline = SwiftUI.Font.custom(Face.heading, size: 16, relativeTo: .headline)
        static let subheading = SwiftUI.Font.custom(Face.headingMedium, size: 15, relativeTo: .subheadline)

        // Reading — IBM Plex Sans
        static let body = SwiftUI.Font.custom(Face.body, size: 16, relativeTo: .body)
        static let bodyMedium = SwiftUI.Font.custom(Face.bodyMedium, size: 16, relativeTo: .body)
        static let callout = SwiftUI.Font.custom(Face.body, size: 15, relativeTo: .callout)
        static let calloutMedium = SwiftUI.Font.custom(Face.bodyMedium, size: 15, relativeTo: .callout)
        static let caption = SwiftUI.Font.custom(Face.body, size: 13, relativeTo: .caption)
        static let captionMedium = SwiftUI.Font.custom(Face.bodyMedium, size: 13, relativeTo: .caption)
        static let captionSmall = SwiftUI.Font.custom(Face.body, size: 11, relativeTo: .caption2)
        static let label = SwiftUI.Font.custom(Face.bodySemibold, size: 13, relativeTo: .caption)

        // Figures — IBM Plex Mono. Tabular by construction, so a count ticking 9 → 10 doesn't
        // shift the layout it sits in.
        static let metricLarge = SwiftUI.Font.custom(Face.monoMedium, size: 30, relativeTo: .title)
        static let metric = SwiftUI.Font.custom(Face.monoMedium, size: 22, relativeTo: .title2)
        static let metricSmall = SwiftUI.Font.custom(Face.mono, size: 14, relativeTo: .subheadline)
        /// Sized to match `caption` and `callout`, for figures set inline inside a line of text.
        /// A figure run has to match the size of the run beside it or the baseline looks broken,
        /// so these exist to pair with the sans tokens rather than to offer new sizes.
        static let metricCallout = SwiftUI.Font.custom(Face.mono, size: 15, relativeTo: .callout)
        static let metricCaption = SwiftUI.Font.custom(Face.mono, size: 13, relativeTo: .caption)
        /// Mono at reading size, for list rows whose whole label is a figure ("250 mL \u{2022} Water").
        /// `metricSmall` would shrink those rows relative to the text around them; this keeps the
        /// size and changes only the face.
        static let metricBody = SwiftUI.Font.custom(Face.mono, size: 16, relativeTo: .body)

        /// Names of every face the app expects to have registered, for the debug check below.
        fileprivate static let allFaces = [
            Face.displayHeavy, Face.display, Face.displayMedium, Face.heading, Face.headingMedium,
            Face.body, Face.bodyMedium, Face.bodySemibold,
            Face.mono, Face.monoMedium,
        ]
    }
}

// MARK: - Headings

/// Applies one of the two largest heading styles: the face, plus the design's tight tracking.
///
/// Tracking can't ride along inside a `Font` — SwiftUI puts it on the view — and it's specified
/// in points while the design gives it in ems (`--tracking-tight: -0.02em`). So it has to be
/// resolved against a point size by hand, and scaled by hand for Dynamic Type: `.tracking()`
/// takes a fixed number that would stay put while the text around it grew, leaving headings
/// visibly over-tightened at large sizes. `@ScaledMetric` scales it against the same text style
/// the font is declared `relativeTo:`, so the two stay in step.
private struct JPHeading: ViewModifier {
    let font: Font
    @ScaledMetric private var tracking: CGFloat

    init(font: Font, baseSize: CGFloat, relativeTo textStyle: Font.TextStyle) {
        self.font = font
        _tracking = ScaledMetric(wrappedValue: baseSize * -0.02, relativeTo: textStyle)
    }

    func body(content: Content) -> some View {
        content.font(font).tracking(tracking)
    }
}

extension View {
    /// The largest heading — screen titles. Only the two display sizes take tight tracking; the
    /// design leaves the smaller headings (`JP.Font.title` and below) at normal tracking.
    func jpDisplayLarge() -> some View {
        modifier(JPHeading(font: JP.Font.displayLarge, baseSize: 28, relativeTo: .largeTitle))
    }

    /// The step-header heading, one size down.
    func jpDisplayMedium() -> some View {
        modifier(JPHeading(font: JP.Font.displayMedium, baseSize: 22, relativeTo: .title2))
    }
}

#if DEBUG
extension JP.Font {
    /// Fails loudly at launch when a bundled font didn't register.
    ///
    /// `Font.custom` falls back to the system face without complaint when a name is wrong or a
    /// `UIAppFonts` entry is missing, which looks like "the design just isn't applied" and is
    /// miserable to track down. Better to say so on the console the first time the app runs.
    static func verifyRegistration() {
        let missing = allFaces.filter { UIFont(name: $0, size: 12) == nil }
        guard !missing.isEmpty else { return }
        assertionFailure(
            """
            Bundled fonts missing: \(missing.joined(separator: ", ")).
            Check UIAppFonts in project.yml lists every .ttf in JPouch/Resources/Fonts, \
            and that these PostScript names match the files.
            """
        )
    }
}
#endif
