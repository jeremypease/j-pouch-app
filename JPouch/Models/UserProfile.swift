import Foundation
import SwiftData

@Model
final class UserProfile {
    var stageRawValue: String
    var stagedSurgeryDate: Date?
    var takedownDate: Date?
    var dailyHydrationTargetML: Int

    var stage: Stage {
        get { Stage(rawValue: stageRawValue) ?? .preOp }
        set { stageRawValue = newValue.rawValue }
    }

    init(stage: Stage = .preOp, dailyHydrationTargetML: Int = 2000) {
        self.stageRawValue = stage.rawValue
        self.dailyHydrationTargetML = dailyHydrationTargetML
    }
}
