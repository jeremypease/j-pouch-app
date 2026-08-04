import SwiftUI
import UIKit

/// The design system's raw values. Nothing outside this file should name a hex code or a bare
/// point value — screens reach for `JP.Color.attention` and `JP.Spacing.lg` instead, so that
/// "make the cards softer" or "warm up the coral" is a one-file change.
enum JP {}

// MARK: - Palette

extension JP {
    /// The raw ramp. Private on purpose: these are ingredients, not the vocabulary. Semantic
    /// names below are what screens use, so a colour can be repointed without a find-and-replace
    /// across every view.
    ///
    /// Teal and coral are sampled directly from the real app icon (`JPouch/Resources/Assets.xcassets/
    /// AppIcon.appiconset/icon-1024.png`) — a cyan-leaning teal background and a coral/salmon
    /// glyph — rather than guessed at before a real icon existed. Emerald/rose are unrelated to
    /// the icon and unchanged.
    fileprivate enum Ramp {
        static let teal50: UInt32 = 0xEDF7F7
        static let teal100: UInt32 = 0xD5ECEC
        static let teal400: UInt32 = 0x4DB2B1
        static let teal500: UInt32 = 0x2F7978
        static let teal600: UInt32 = 0x256563
        static let teal700: UInt32 = 0x1C4F4E
        static let teal900: UInt32 = 0x0E2A2A

        static let coral300: UInt32 = 0xED9982
        static let coral400: UInt32 = 0xE96C49
        static let coral500: UInt32 = 0xDF4920
        static let coral600: UInt32 = 0xB83F1E

        static let emerald400: UInt32 = 0x34D399
        static let emerald700: UInt32 = 0x047857

        static let rose500: UInt32 = 0xF43F5E
        static let rose700: UInt32 = 0xBE123C
    }

    enum Color {
        /// Text and interactive tint.
        ///
        /// Reads from `AccentColor` in the asset catalog, kept in sync with `Ramp.teal500`/
        /// `teal300` here — 5.1:1 against white in light mode, comfortably past the 4.5:1 AA
        /// threshold for text. The same brand teal still appears, as `brandFill`, wherever it's
        /// a shape rather than text.
        static let accent = SwiftUI.Color.accentColor

        /// The saturated brand teal, for filled shapes and progress — never for text on white.
        static let brandFill = adaptive(light: Ramp.teal500, dark: Ramp.teal400)

        /// A wash for selected rows and icon circles.
        static let brandSurface = adaptive(light: Ramp.teal50, dark: Ramp.teal900)
        static let brandSurfaceStrong = adaptive(light: Ramp.teal100, dark: Ramp.teal700)

        /// Pattern flags. Coral, never red: these mean "worth raising with your GI", not
        /// "emergency", and J-Pouch never diagnoses. 5.1:1 against the light background, 6.9:1
        /// against the dark background — both clear AA.
        static let attention = adaptive(light: Ramp.coral600, dark: Ramp.coral300)
        static let attentionFill = adaptive(light: Ramp.coral500, dark: Ramp.coral400)

        /// Something actually went wrong — a failed save or sync.
        static let critical = adaptive(light: Ramp.rose700, dark: Ramp.rose500)

        static let confirmation = adaptive(light: Ramp.emerald700, dark: Ramp.emerald400)

        /// Cards read as raised surfaces against the grouped background. Using the system
        /// grouped colours rather than fixed greys keeps dark mode and Increase Contrast working
        /// without a second palette.
        static let pageBackground = SwiftUI.Color(uiColor: .systemGroupedBackground)
        static let cardSurface = SwiftUI.Color(uiColor: .secondarySystemGroupedBackground)
        static let inputSurface = SwiftUI.Color(uiColor: .tertiarySystemGroupedBackground)
        static let separator = SwiftUI.Color(uiColor: .separator)

        static let primaryText = SwiftUI.Color.primary
        static let secondaryText = SwiftUI.Color.secondary

        private static func adaptive(light: UInt32, dark: UInt32) -> SwiftUI.Color {
            SwiftUI.Color(uiColor: UIColor { traits in
                UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
            })
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Metrics

extension JP {
    /// A 4-point scale. Anything off it is a one-off that should justify itself in place.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 16
        static let control: CGFloat = 12
        static let tag: CGFloat = 8
    }

    /// Barely-there elevation. Enough to lift a card off the page without the drop shadows of a
    /// decade ago.
    enum Shadow {
        static let color = SwiftUI.Color.black.opacity(0.06)
        static let radius: CGFloat = 8
        static let y: CGFloat = 2
    }

    /// Minimum tap target. Apple's HIG floor, named so it's obvious when a control is at it.
    enum Layout {
        static let minimumTapTarget: CGFloat = 44
    }
}
