import Foundation

/// The two things J-Pouch nudges about on a daily rhythm, separate from medication courses.
enum ReminderKind: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Drinking, and recording it. Dehydration is the risk that actually lands people in
    /// hospital, so this is the one worth defaulting on.
    case hydration
    /// Recording output. Deliberately framed as logging rather than as a prompt to go: nobody
    /// needs reminding to have a bowel movement, they need reminding to write it down, and the
    /// pattern flags are only as good as how completely the day was logged.
    case logging

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hydration: "Fluid reminders"
        case .logging: "Logging reminders"
        }
    }

    var explanation: String {
        switch self {
        case .hydration:
            "Drinking steadily through the day is easier than catching up after you've fallen behind."
        case .logging:
            "A nudge to record what's happened. Days with nothing logged are gaps, and the app won't guess across them."
        }
    }
}

/// How often to be nudged. Presets are ordinary schedules within waking hours rather than
/// arbitrary intervals — a reminder at 3am helps nobody.
enum ReminderCadence: String, Codable, CaseIterable, Identifiable, Sendable {
    case off
    case light
    case standard
    case frequent
    case custom

    var id: String { rawValue }

    /// Presets that appear as choices. `custom` is offered separately, since picking it means
    /// editing times rather than choosing a frequency.
    static var presets: [ReminderCadence] { [.off, .light, .standard, .frequent] }

    func displayName(for kind: ReminderKind) -> String {
        switch (self, kind) {
        case (.off, _): "Off"
        case (.light, .hydration): "Twice a day"
        case (.standard, .hydration): "Every few hours"
        case (.frequent, .hydration): "Every 2 hours"
        case (.light, .logging): "Once a day"
        case (.standard, .logging): "Twice a day"
        case (.frequent, .logging): "Three times a day"
        case (.custom, _): "Custom"
        }
    }

    /// Minutes past midnight, local time. Empty means nothing is scheduled.
    ///
    /// Custom returns nothing of its own: the times come from whatever the person chose, which
    /// is stored rather than derived.
    func times(for kind: ReminderKind) -> [Int] {
        func at(_ hours: Int...) -> [Int] { hours.map { $0 * 60 } }

        switch (self, kind) {
        case (.off, _), (.custom, _):
            return []
        case (.light, .hydration):
            return at(9, 19)
        case (.standard, .hydration):
            return at(9, 12, 15, 18)
        case (.frequent, .hydration):
            return at(8, 10, 12, 14, 16, 18, 20)
        case (.light, .logging):
            return at(20)
        case (.standard, .logging):
            return at(13, 20)
        case (.frequent, .logging):
            return at(10, 15, 20)
        }
    }

    /// Hydration defaults on because dehydration is the risk with real consequences; logging
    /// defaults to a single evening nudge, which is enough to close the day's gaps without
    /// becoming another thing buzzing at someone who already manages a lot of them.
    static func `default`(for kind: ReminderKind) -> ReminderCadence {
        switch kind {
        case .hydration: .standard
        case .logging: .light
        }
    }
}

/// A schedule as plain values, ready to hand to the scheduler.
struct DailyReminderSchedule: Sendable, Equatable {
    var kind: ReminderKind
    var minutes: [Int]

    var isOn: Bool { !minutes.isEmpty }
}

extension Int {
    /// "9:00 AM" for a minutes-past-midnight value, in the user's locale.
    var asTimeOfDay: String {
        var components = DateComponents()
        components.hour = self / 60
        components.minute = self % 60
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
