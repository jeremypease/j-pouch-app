import SwiftUI
import UIKit

/// Global UIKit chrome — navigation bar title font and tab bar tint/font — that SwiftUI's
/// per-view modifiers can't reach without touching every screen individually. Call once at
/// launch from `JPouchApp.init()`.
///
/// Deliberately leaves navigation bar and tab bar *backgrounds* at the system default rather
/// than tinting them teal. The design system only defines a light-mode palette (see
/// `design-system/readme.md`), and a hardcoded background would look right in light mode but
/// clash against system Dark Mode everywhere else in the app. Typography and accent tint read
/// fine in both modes, so those are what this brands; background color is left for a follow-up
/// once (or if) a dark palette exists.
enum JPouchAppearance {
    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }

    /// `UIFont(name:size:)` returns nil if the PostScript name doesn't resolve — which would
    /// otherwise mean a silent fallback to the system font with no signal anything's wrong.
    /// Falling back explicitly to a system font here, rather than force-unwrapping, keeps a
    /// typo'd font name from crashing launch; if this ever fires in practice it means a name in
    /// this file drifted from what's actually registered in `UIAppFonts`.
    private static func font(name: String, size: CGFloat, systemWeight: UIFont.Weight) -> UIFont {
        UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size, weight: systemWeight)
    }

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: font(name: "ManropeExtraLight-Bold", size: 17, systemWeight: .bold),
        ]
        appearance.largeTitleTextAttributes = [
            .font: font(name: "ManropeExtraLight-ExtraBold", size: 34, systemWeight: .heavy),
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(JPouchColor.gray400)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(JPouchColor.gray400),
            .font: font(name: "IBMPlexSans-Medium", size: 11, systemWeight: .medium),
        ]
        itemAppearance.selected.iconColor = UIColor(JPouchColor.primary)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(JPouchColor.primary),
            .font: font(name: "IBMPlexSans-SemiBold", size: 11, systemWeight: .semibold),
        ]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
