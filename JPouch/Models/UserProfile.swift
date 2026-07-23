import Foundation
import SwiftData

@Model
final class UserProfile {
    /// Set only when the user has overridden the date-derived stage; nil means "follow the dates".
    var manualStageRawValue: String?
    var stagedSurgeryDate: Date?
    var takedownDate: Date?
    var dailyHydrationTargetML: Int

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

    init(stage: Stage = .preOp, dailyHydrationTargetML: Int = 2000) {
        self.manualStageRawValue = stage.rawValue
        self.dailyHydrationTargetML = dailyHydrationTargetML
    }
}
