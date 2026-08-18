import Foundation
import Testing
@testable import JPouch

@Suite("Reminder cadences")
struct ReminderCadenceTests {

    @Test("Off schedules nothing for either kind")
    func offIsEmpty() {
        for kind in ReminderKind.allCases {
            #expect(ReminderCadence.off.times(for: kind).isEmpty)
        }
    }

    /// A reminder in the middle of the night is worse than none: it wakes someone who is
    /// already sleeping badly, and it's the fastest route to the category being switched off.
    @Test("No preset fires outside waking hours", arguments: ReminderKind.allCases)
    func presetsStayWithinWakingHours(kind: ReminderKind) {
        for cadence in ReminderCadence.presets {
            for minute in cadence.times(for: kind) {
                #expect(minute >= 7 * 60, "\(cadence) for \(kind) fires at \(minute.asTimeOfDay)")
                #expect(minute <= 21 * 60, "\(cadence) for \(kind) fires at \(minute.asTimeOfDay)")
            }
        }
    }

    @Test("Frequency increases with cadence", arguments: ReminderKind.allCases)
    func cadenceOrderingIsMonotonic(kind: ReminderKind) {
        let light = ReminderCadence.light.times(for: kind).count
        let standard = ReminderCadence.standard.times(for: kind).count
        let frequent = ReminderCadence.frequent.times(for: kind).count
        #expect(light < standard)
        #expect(standard < frequent)
    }

    @Test("Preset times are sorted and unique")
    func timesAreSortedAndUnique() {
        for kind in ReminderKind.allCases {
            for cadence in ReminderCadence.presets {
                let times = cadence.times(for: kind)
                #expect(times == times.sorted())
                #expect(Set(times).count == times.count)
            }
        }
    }

    /// Hydration is the one with a hospital-shaped downside, so it starts on; logging starts
    /// at a single evening nudge rather than adding to the day's noise.
    @Test("Defaults are on, and lighter for logging than hydration")
    func defaultsAreSensible() {
        let hydration = ReminderCadence.default(for: .hydration)
        let logging = ReminderCadence.default(for: .logging)
        #expect(hydration != .off)
        #expect(logging != .off)
        #expect(logging.times(for: .logging).count < hydration.times(for: .hydration).count)
    }
}

@Suite("Profile reminder storage")
struct ProfileReminderTests {

    @Test("Choosing a preset replaces the stored times")
    func presetSetsTimes() {
        let profile = UserProfile()
        profile.setReminders(for: .hydration, cadence: .frequent)
        #expect(profile.hydrationReminderMinutes == ReminderCadence.frequent.times(for: .hydration))
        #expect(profile.cadence(for: .hydration) == .frequent)
    }

    @Test("Off clears the times, so nothing is left scheduled")
    func offClearsTimes() {
        let profile = UserProfile()
        profile.setReminders(for: .logging, cadence: .standard)
        #expect(!profile.loggingReminderMinutes.isEmpty)

        profile.setReminders(for: .logging, cadence: .off)
        #expect(profile.loggingReminderMinutes.isEmpty)
    }

    @Test("Custom keeps the supplied times, sorted")
    func customKeepsSuppliedTimes() {
        let profile = UserProfile()
        profile.setReminders(for: .hydration, cadence: .custom, customMinutes: [1200, 480, 900])
        #expect(profile.hydrationReminderMinutes == [480, 900, 1200])
        #expect(profile.cadence(for: .hydration) == .custom)
    }

    @Test("The two kinds don't interfere with each other")
    func kindsAreIndependent() {
        let profile = UserProfile()
        profile.setReminders(for: .hydration, cadence: .off)
        profile.setReminders(for: .logging, cadence: .frequent)
        #expect(profile.hydrationReminderMinutes.isEmpty)
        #expect(profile.loggingReminderMinutes == ReminderCadence.frequent.times(for: .logging))
    }
}
