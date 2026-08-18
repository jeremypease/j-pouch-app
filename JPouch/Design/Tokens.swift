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
    /// Straight from the design system export (`tokens/colors.css`). Teal is the primary,
    /// tan is the sole accent, and the neutrals are deliberately warm rather than blue-grey.
    ///
    /// The brief is explicit that semantic colours stay in the same warm-muted family: this is a
    /// body-function tracker, and loud success/fail colour reads punitive. So no saturated red
    /// or green — danger is a muted brick, success is simply a deeper teal.
    fileprivate enum Ramp {
        static let teal900: UInt32 = 0x12271F
        static let teal800: UInt32 = 0x183A2F
        static let teal700: UInt32 = 0x215849
        static let teal600: UInt32 = 0x2C6B58
        static let teal500: UInt32 = 0x3C7A6A
        static let teal400: UInt32 = 0x5A9484
        static let teal300: UInt32 = 0x7FB5A6
        static let teal200: UInt32 = 0xA8CDC0
        static let teal100: UInt32 = 0xD3E8E0
        static let teal50: UInt32 = 0xEAF5F2

        static let tan700: UInt32 = 0xA8703E
        static let tan600: UInt32 = 0xC98A52
        static let tan500: UInt32 = 0xE0A568
        static let tan400: UInt32 = 0xE8B384
        static let tan300: UInt32 = 0xF0CBA3
        static let tan100: UInt32 = 0xFAF0E3

        static let gray900: UInt32 = 0x1C211F
        static let gray800: UInt32 = 0x2C332F
        static let gray700: UInt32 = 0x3F4744
        static let gray500: UInt32 = 0x6B756F
        static let gray300: UInt32 = 0xA9B0AC
        static let gray100: UInt32 = 0xE3E7E4
        static let gray50: UInt32 = 0xF6F8F6

        static let white: UInt32 = 0xFFFFFF

        static let red600: UInt32 = 0x9A4432
        static let red500: UInt32 = 0xB0503F
        static let red100: UInt32 = 0xF5E2DD
    }

    enum Color {
        /// Text and interactive tint. Mirrors `AccentColor` in the asset catalog, which is set
        /// to the same teal-500/teal-300 pair.
        static let accent = SwiftUI.Color.accentColor

        /// The primary teal, for filled shapes and progress.
        static let brandFill = adaptive(light: Ramp.teal500, dark: Ramp.teal300)

        /// Washes for selected rows and icon circles.
        static let brandSurface = adaptive(light: Ramp.teal50, dark: Ramp.teal900)
        static let brandSurfaceStrong = adaptive(light: Ramp.teal100, dark: Ramp.teal800)

        /// Pattern flags map to the system's *warning*, not danger: they mean "worth raising
        /// with your GI", and the brief rules out alarm colour for exactly this reason. Tan-700
        /// rather than tan-400 for text, which needs the contrast.
        static let attention = adaptive(light: Ramp.tan700, dark: Ramp.tan300)
        static let attentionFill = adaptive(light: Ramp.tan500, dark: Ramp.tan400)

        /// Reserved for something actually going wrong — a failed save or sync. Muted brick,
        /// per the palette; never a saturated red.
        static let critical = adaptive(light: Ramp.red600, dark: Ramp.red100)

        static let confirmation = adaptive(light: Ramp.teal600, dark: Ramp.teal300)

        /// Pale teal page, white cards. Dark mode uses the darkest teal rather than black, so
        /// the warm-teal cast survives at night instead of going neutral.
        static let pageBackground = adaptive(light: Ramp.teal50, dark: Ramp.teal900)
        static let cardSurface = adaptive(light: Ramp.white, dark: Ramp.teal800)
        static let inputSurface = adaptive(light: Ramp.gray50, dark: Ramp.teal700)
        static let separator = adaptive(light: Ramp.gray100, dark: Ramp.teal700)

        /// Warm greys, not the system blue-greys.
        static let primaryText = adaptive(light: Ramp.gray900, dark: Ramp.gray50)
        static let secondaryText = adaptive(light: Ramp.gray700, dark: Ramp.gray300)
        static let mutedText = adaptive(light: Ramp.gray500, dark: Ramp.gray300)

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
        static let ml: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let section: CGFloat = 48
    }

    enum Radius {
        /// "Rounded but not pill-happy" — the spec is explicit: cards 20, buttons and inputs 14,
        /// and only small chips and badges go fully round.
        static let card: CGFloat = 20
        static let control: CGFloat = 14
        static let button: CGFloat = 14
        static let input: CGFloat = 12
        static let tag: CGFloat = 999
    }

    /// Barely-there elevation. Enough to lift a card off the page without the drop shadows of a
    /// decade ago.
    /// `--shadow-sm` from the export: cards lift barely off the background, nothing floats.
    /// The tint is the warm near-black the system uses for shadows, not pure black.
    enum Shadow {
        static let color = SwiftUI.Color(red: 28/255, green: 33/255, blue: 31/255).opacity(0.07)
        static let radius: CGFloat = 6
        static let y: CGFloat = 2
    }

    /// Minimum tap target. Apple's HIG floor, named so it's obvious when a control is at it.
    enum Layout {
        static let minimumTapTarget: CGFloat = 44
    }
}
