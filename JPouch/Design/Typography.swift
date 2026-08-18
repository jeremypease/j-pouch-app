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

        /// Names of every face the app expects to have registered, for the debug check below.
        fileprivate static let allFaces = [
            Face.displayHeavy, Face.display, Face.displayMedium, Face.heading, Face.headingMedium,
            Face.body, Face.bodyMedium, Face.bodySemibold,
            Face.mono, Face.monoMedium,
        ]
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
