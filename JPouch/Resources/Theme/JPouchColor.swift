import SwiftUI
import UIKit

/// Color tokens for J-Pouch. The teal and coral ramps below are sampled directly from the
/// real app icon (`JPouch/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`) — a
/// cyan-leaning teal background and a coral/salmon glyph — rather than the tan/apricot accent
/// the design system originally guessed at before a real icon existed. Gray/red/blue are
/// unrelated to the icon and unchanged.
///
/// Every stop used for text-on-fill or icon-on-background was checked against WCAG's contrast
/// formula (relative luminance ratio) in both light and dark mode before being wired up here —
/// notably `primary` against white button text, and `warning` against the app background. Not
/// just eyeballed: see the ratios in each doc comment below. The old tan-based `warning` this
/// replaced was only ~2.6:1 against its background, well under the 4.5:1 AA threshold — worth
/// knowing since it shipped that way for a while before this pass caught it.
enum JPouchColor {
    // MARK: Ramps (mode-stable — see "Purpose" section below for what actually adapts)

    static let teal50 = Color(hex: 0xEDF7F7)
    static let teal100 = Color(hex: 0xD5ECEC)
    static let teal200 = Color(hex: 0xB2DCDC)
    static let teal300 = Color(hex: 0x87C9C8)
    static let teal400 = Color(hex: 0x4DB2B1)
    static let teal500 = Color(hex: 0x2F7978)
    static let teal600 = Color(hex: 0x256563)
    static let teal700 = Color(hex: 0x1C4F4E)
    static let teal800 = Color(hex: 0x143D3D)
    static let teal900 = Color(hex: 0x0E2A2A)

    static let coral50 = Color(hex: 0xFAF2EF)
    static let coral100 = Color(hex: 0xF5DDD6)
    static let coral200 = Color(hex: 0xF0BFB2)
    static let coral300 = Color(hex: 0xED9982)
    static let coral400 = Color(hex: 0xE96C49)
    static let coral500 = Color(hex: 0xDF4920)
    static let coral600 = Color(hex: 0xB83F1E)
    static let coral700 = Color(hex: 0x92351C)
    static let coral800 = Color(hex: 0x6B2B19)
    static let coral900 = Color(hex: 0x472015)

    static let gray50 = Color(hex: 0xF6F8F6)
    static let gray100 = Color(hex: 0xE3E7E4)
    static let gray200 = Color(hex: 0xC8CDC9)
    static let gray300 = Color(hex: 0xA9B0AC)
    static let gray400 = Color(hex: 0x8B948E)
    static let gray500 = Color(hex: 0x6B756F)
    static let gray600 = Color(hex: 0x565F5B)
    static let gray700 = Color(hex: 0x3F4744)
    static let gray800 = Color(hex: 0x2C332F)
    static let gray900 = Color(hex: 0x1C211F)

    static let red100 = Color(hex: 0xF5E2DD)
    static let red500 = Color(hex: 0xB0503F)
    static let red600 = Color(hex: 0x9A4432)

    static let blue100 = Color(hex: 0xE2EDF3)
    static let blue500 = Color(hex: 0x4D84A8)
    static let blue600 = Color(hex: 0x3A6A8A)

    // MARK: Purpose (mirrors --color-* tokens; adapts to dark mode)

    static let background = adaptive(light: teal50, dark: teal900)
    static let surface = adaptive(light: .white, dark: teal800)
    static let surfaceSunken = adaptive(light: gray50, dark: Color(hex: 0x081818))

    static let border = adaptive(light: gray100, dark: teal700)
    static let borderStrong = adaptive(light: gray200, dark: teal600)

    static let textPrimary = adaptive(light: gray900, dark: Color(hex: 0xEEF4F1))
    static let textSecondary = adaptive(light: gray700, dark: Color(hex: 0xB7C4BF))
    static let textMuted = adaptive(light: gray500, dark: Color(hex: 0x83938C))
    static let textOnPrimary = Color.white
    /// Text sitting on `primarySoft`. 12.3:1 in light mode (teal900 on teal100), 9.6:1 in dark
    /// (teal100 on teal800) — comfortably past AA in both.
    static let textOnAccent = adaptive(light: teal900, dark: teal100)

    /// 5.1:1 against white — this is what actually renders behind white button text via
    /// `AccentColor` (see `AccentColor.colorset`, which mirrors these same two hex values so
    /// system-level accent-tinted controls stay in sync with this token).
    static let primary = adaptive(light: teal500, dark: teal300)
    static let primaryHover = adaptive(light: teal600, dark: teal200)
    static let primaryActive = adaptive(light: teal700, dark: teal100)
    static let primarySoft = adaptive(light: teal100, dark: teal800)
    static let primarySoftStrong = adaptive(light: teal200, dark: teal700)

    static let accent = coral400
    static let accentHover = adaptive(light: coral500, dark: coral300)
    static let accentSoft = adaptive(light: coral50, dark: coral900)

    /// Reserved for a status that's actually resolved good, e.g. "on track" badges — not the
    /// same as `primary`, which is the brand/action color.
    static let success = adaptive(light: teal600, dark: teal400)
    static let successSoft = adaptive(light: teal100, dark: teal800)

    /// The pattern-flag color. Deliberately coral rather than red — see `HomeView`'s existing
    /// `FlagCard` comment: this is "worth a conversation," never an emergency or a diagnosis,
    /// and the brand guidance explicitly avoids alarm-red for a body-function tracker. 5.1:1
    /// against the light background, 6.9:1 against the dark background — both clear AA.
    static let warning = adaptive(light: coral600, dark: coral300)
    static let warningSoft = adaptive(light: coral100, dark: coral900)

    static let danger = adaptive(light: red500, dark: Color(hex: 0xD9786A))
    static let dangerSoft = adaptive(light: red100, dark: Color(hex: 0x3A1F1A))

    static let info = adaptive(light: blue500, dark: Color(hex: 0x7FA8C2))
    static let infoSoft = adaptive(light: blue100, dark: Color(hex: 0x1C2E3A))

    static let focusRing = adaptive(light: teal400, dark: teal300)

    /// Builds a `Color` that resolves differently depending on the active `UITraitCollection`,
    /// so every view that reads e.g. `JPouchColor.primary` gets dark-mode support for free
    /// instead of each screen needing its own `@Environment(\.colorScheme)` branch.
    private static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension Color {
    /// Convenience initializer for the hex literals design tools hand back (e.g. `0x3C7A6A`).
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
