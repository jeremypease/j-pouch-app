import SwiftUI
import SwiftData

struct RootView: View {
    /// Sorted so the choice is deterministic when more than one profile exists. An unsorted
    /// `first` could return a different profile between launches.
    @Query(sort: \UserProfile.createdAt, order: .forward) private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    /// How long to let CloudKit deliver an existing profile before concluding this really is a
    /// new user. Reinstalling on a new phone otherwise shows onboarding while the sync is still
    /// in flight, and completing it creates a second profile that then fights the synced one.
    private static let syncGracePeriod: Duration = .seconds(3)

    @State private var hasWaitedForSync = false

    var body: some View {
        Group {
            if let profile = profiles.first {
                MainTabView(profile: profile)
            } else if hasWaitedForSync {
                OnboardingView()
            } else {
                ProgressView()
                    .task {
                        try? await Task.sleep(for: Self.syncGracePeriod)
                        hasWaitedForSync = true
                    }
            }
        }
        .onChange(of: profiles.count) {
            removeDuplicateProfiles()
        }
    }

    /// A duplicate can still slip through — the grace period is a heuristic, not a guarantee,
    /// and sync can arrive long after onboarding was completed offline. Profiles hold only
    /// settings (log entries are standalone), so collapsing to the earliest one loses nothing
    /// but the duplicate's settings, and leaving both would keep the app picking arbitrarily.
    private func removeDuplicateProfiles() {
        guard profiles.count > 1 else { return }
        for duplicate in profiles.dropFirst() {
            modelContext.delete(duplicate)
        }
    }
}

struct MainTabView: View {
    let profile: UserProfile

    @Query private var medications: [MedicationEntry]

    var body: some View {
        TabView {
            HomeView(profile: profile)
                .tabItem { Label("Home", systemImage: "house") }
            LogView()
                .tabItem { Label("Log", systemImage: "plus.circle") }
            TrendsView(profile: profile)
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            SettingsView(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            // Rebuild reminders at launch so finished courses stop firing even though nothing
            // ran while the app was closed, and so a phone restored from iCloud schedules its
            // own — notifications don't sync with the data.
            let reminders = medications.map { $0.reminderSnapshot() }
            await NotificationManager.shared.sync(reminders)
        }
    }
}
