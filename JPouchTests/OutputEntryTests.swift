import Foundation
import Testing
@testable import JPouch

@Suite("PainLevel summaries")
struct PainLevelTests {
    @Test("Every level 0 through 5 has a non-empty description")
    func allLevelsHaveASummary() {
        for level in 0...5 {
            #expect(!PainLevel.summary(for: level).isEmpty)
        }
    }

    @Test("An out-of-range level falls back to an empty string rather than crashing")
    func outOfRangeFallsBackToEmpty() {
        #expect(PainLevel.summary(for: -1).isEmpty)
        #expect(PainLevel.summary(for: 6).isEmpty)
    }
}

@Suite("UserProfile ostomy flag")
struct UserProfileOstomyTests {
    @Test("Defaults to false so existing profiles are unaffected")
    func defaultsToFalse() {
        #expect(UserProfile().hasOstomy == false)
    }

    @Test("Is independent of Stage, which stays purely date-derived")
    func independentOfStage() {
        let profile = UserProfile(manualStage: .adaptation, hasOstomy: true)
        #expect(profile.hasOstomy == true)
        #expect(profile.stage == .adaptation)
    }
}
