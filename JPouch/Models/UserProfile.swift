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

    /// Minutes past midnight. Empty means that kind of reminder is off — no separate enabled
    /// flag, so the two can never disagree about whether anything is scheduled.
    var hydrationReminderMinutes: [Int] = []
    var loggingReminderMinutes: [Int] = []
    /// Kept alongside the times only so the settings UI can show which preset is selected;
    /// the times are what actually gets scheduled.
    var hydrationCadenceRawValue: String = ReminderCadence.standard.rawValue
    var loggingCadenceRawValue: String = ReminderCadence.light.rawValue

    func cadence(for kind: ReminderKind) -> ReminderCadence {
        let raw = kind == .hydration ? hydrationCadenceRawValue : loggingCadenceRawValue
        return ReminderCadence(rawValue: raw) ?? .default(for: kind)
    }

    func reminderMinutes(for kind: ReminderKind) -> [Int] {
        kind == .hydration ? hydrationReminderMinutes : loggingReminderMinutes
    }

    /// Sets both halves together so a cadence can't end up describing times that aren't
    /// scheduled. Custom keeps whatever times are passed in; every preset derives its own.
    func setReminders(for kind: ReminderKind, cadence: ReminderCadence, customMinutes: [Int] = []) {
        let minutes = cadence == .custom ? customMinutes.sorted() : cadence.times(for: kind)
        switch kind {
        case .hydration:
            hydrationCadenceRawValue = cadence.rawValue
            hydrationReminderMinutes = minutes
        case .logging:
            loggingCadenceRawValue = cadence.rawValue
            loggingReminderMinutes = minutes
        }
    }

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
