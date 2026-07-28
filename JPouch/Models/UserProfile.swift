import Foundation
import SwiftData

@Model
final class UserProfile {
    /// Used to pick deterministically when CloudKit sync has produced more than one profile.
    var createdAt: Date = Date.now
    /// Set only when the user has overridden the date-derived stage; nil means "follow the dates".
    var manualStageRawValue: String?
    var stagedSurgeryDate: Date?
    var takedownDate: Date?
    var dailyHydrationTargetML: Int = 2000

    var manualStageOverride: Stage? {
        get { manualStageRawValue.flatMap { Stage(rawValue: $0) } }
        set { manualStageRawValue = newValue?.rawValue }
    }

    /// The stage actually shown in the app: the manual override if set, otherwise inferred from surgery dates.
    var stage: Stage {
        manualStageOverride
            ?? Stage.derived(stagedSurgeryDate: stagedSurgeryDate, takedownDate: takedownDate)
            ?? .preOp
    }

    /// Takes the override explicitly rather than a plain stage. The previous initializer set an
    /// override unconditionally, which pinned every new user to whatever they picked during
    /// onboarding and meant the date-based derivation never ran for anyone.
    init(
        manualStage: Stage? = nil,
        stagedSurgeryDate: Date? = nil,
        takedownDate: Date? = nil,
        dailyHydrationTargetML: Int = 2000,
        createdAt: Date = .now
    ) {
        self.manualStageRawValue = manualStage?.rawValue
        self.stagedSurgeryDate = stagedSurgeryDate
        self.takedownDate = takedownDate
        self.dailyHydrationTargetML = dailyHydrationTargetML
        self.createdAt = createdAt
    }
}
