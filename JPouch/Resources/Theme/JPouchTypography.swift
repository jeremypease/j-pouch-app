import SwiftUI

/// Typography from `design-system/tokens/typography.css` + `fonts.css`: Manrope (display),
/// IBM Plex Sans (body), IBM Plex Mono (numbers/timestamps/dosages) — see
/// `JPouch/Resources/Fonts/` for the bundled .ttf files (OFL-licensed, converted from Google
/// Fonts' woff2 distributions) and `project.yml`'s `UIAppFonts` for how they're registered.
///
/// One upstream quirk worth knowing about: the Manrope static builds this was converted from
/// mis-name every weight as a variant of "ExtraLight" in their internal metadata (e.g. the
/// 800-weight file's real PostScript name is `ManropeExtraLight-ExtraBold`, not
/// `Manrope-ExtraBold`) — a labeling bug in that build, not a sign the wrong weight got bundled.
/// The glyphs themselves are the correct weight; only the name is odd. `manropeName(for:)` below
/// is the one place that has to know about it.
enum JPouchFont {
    /// Only the weights actually bundled in `Resources/Fonts/` — kept as its own type instead of
    /// reusing SwiftUI's `Font.Weight` so a typo can't silently fall back to a weight nothing
    /// shipped for.
    enum Weight {
        case regular, medium, semibold, bold, extraBold
    }

    private static func manropeName(for weight: Weight) -> String {
        switch weight {
        case .regular: "ManropeExtraLight-Regular"
        case .medium: "ManropeExtraLight-Medium"
        case .semibold: "ManropeExtraLight-SemiBold"
        case .bold: "ManropeExtraLight-Bold"
        case .extraBold: "ManropeExtraLight-ExtraBold"
        }
    }

    private static func plexSansName(for weight: Weight) -> String {
        switch weight {
        case .regular: "IBMPlexSans-Regular"
        case .medium: "IBMPlexSans-Medium"
        case .semibold: "IBMPlexSans-SemiBold"
        case .bold, .extraBold: "IBMPlexSans-Bold"
        }
    }

    private static func plexMonoName(for weight: Weight) -> String {
        switch weight {
        case .regular: "IBMPlexMono-Regular"
        case .medium: "IBMPlexMono-Medium"
        case .semibold: "IBMPlexMono-SemiBold"
        case .bold, .extraBold: "IBMPlexMono-Bold"
        }
    }

    // MARK: Display (Manrope)

    /// `relativeTo:` is what makes this actually scale with Dynamic Type — a plain
    /// `Font.custom(_:size:)` without it stays a fixed pixel size regardless of the user's text
    /// size setting, which the rest of this app is careful about (see `AdaptiveLabeledRow`,
    /// the accessibility-size checks in `OnboardingView`).
    static func display(_ size: CGFloat, weight: Weight = .bold, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(manropeName(for: weight), size: size, relativeTo: style)
    }

    static var displayXL: Font { display(22, weight: .extraBold, relativeTo: .title2) }
    static var display2XL: Font { display(26, weight: .extraBold, relativeTo: .title) }
    static var display3XL: Font { display(32, weight: .extraBold, relativeTo: .largeTitle) }
    static var displayLG: Font { display(18, weight: .bold, relativeTo: .headline) }

    // MARK: Body (IBM Plex Sans)

    static func body(_ size: CGFloat, weight: Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(plexSansName(for: weight), size: size, relativeTo: style)
    }

    static var bodyMD: Font { body(16, relativeTo: .body) }
    static var bodyMDMedium: Font { body(16, weight: .medium, relativeTo: .body) }
    static var bodySM: Font { body(14, relativeTo: .subheadline) }
    static var bodyXS: Font { body(12, relativeTo: .caption) }
    static var body2XS: Font { body(11, relativeTo: .caption2) }

    // MARK: Mono (IBM Plex Mono — timestamps, doses, counts)

    static func mono(_ size: CGFloat, weight: Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(plexMonoName(for: weight), size: size, relativeTo: style)
    }

    static var monoSM: Font { mono(14, weight: .medium, relativeTo: .subheadline) }
    static var monoXS: Font { mono(12, relativeTo: .caption) }
}
