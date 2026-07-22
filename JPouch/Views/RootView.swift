import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let profile = profiles.first {
            MainTabView(profile: profile)
        } else {
            OnboardingView(onComplete: { stage in
                let profile = UserProfile(stage: stage)
                modelContext.insert(profile)
            })
        }
    }
}

struct MainTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            HomeView(profile: profile)
                .tabItem { Label("Home", systemImage: "house") }
            LogView()
                .tabItem { Label("Log", systemImage: "plus.circle") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            SettingsView(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
