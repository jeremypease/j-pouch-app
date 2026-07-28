import Foundation
import Testing
@testable import JPouch

@Suite("Stage — onboarding override")
struct StageOverrideTests {

    /// The bug this guards: the old initializer always stored an override, so the date-based
    /// derivation never ran for anyone and stages never advanced on their own.
    @Test("Stores no override when the date already derives to the chosen stage")
    func noOverrideWhenDatesAgree() {
        let override = Stage.override(
            forPicked: .adaptation,
            stagedSurgeryDate: nil,
            takedownDate: testDaysAgo(60),
            asOf: testToday
        )
        #expect(override == nil)
    }

    @Test("Keeps the explicit choice when the dates say something different")
    func overrideWhenDatesDisagree() {
        // Takedown two years ago derives to long-term maintenance, but they said adaptation.
        let override = Stage.override(
            forPicked: .adaptation,
            stagedSurgeryDate: nil,
            takedownDate: testDaysAgo(730),
            asOf: testToday
        )
        #expect(override == .adaptation)
    }

    @Test("Keeps the explicit choice when no date was given")
    func overrideWhenNoDates() {
        let override = Stage.override(
            forPicked: .stagedSurgery,
            stagedSurgeryDate: nil,
            takedownDate: nil,
            asOf: testToday
        )
        #expect(override == .stagedSurgery)
    }

    @Test("A profile with only dates advances stage on its own over time")
    func derivesAcrossTheAdaptationBoundary() {
        let takedown = testDaysAgo(400)
        #expect(Stage.derived(stagedSurgeryDate: nil, takedownDate: takedown, asOf: testToday) == .longTermMaintenance)

        let recentTakedown = testDaysAgo(30)
        #expect(Stage.derived(stagedSurgeryDate: nil, takedownDate: recentTakedown, asOf: testToday) == .adaptation)
    }

    /// `UserProfile.stage` deliberately reads the live clock — that's what lets it advance on
    /// its own — so this one works in real time rather than against the fixed test date.
    @Test("A profile built the way onboarding builds it follows its dates")
    func profileFollowsDates() throws {
        let takedown = try #require(Calendar.current.date(byAdding: .day, value: -60, to: .now))
        let profile = UserProfile(
            manualStage: Stage.override(
                forPicked: .adaptation,
                stagedSurgeryDate: nil,
                takedownDate: takedown
            ),
            takedownDate: takedown
        )
        #expect(profile.manualStageOverride == nil)
        #expect(profile.stage == .adaptation)
    }
}

@Suite("NotificationManager — reminder plan")
struct ReminderPlanTests {

    private func medication(
        reminderEnabled: Bool = true,
        minutes: [Int] = [8 * 60],
        startDate: Date = testDaysAgo(1),
        endDate: Date? = nil
    ) -> MedicationEntry {
        MedicationEntry(
            name: "Ciprofloxacin",
            dosage: "500mg",
            isAntibiotic: true,
            startDate: startDate,
            endDate: endDate,
            reminderEnabled: reminderEnabled,
            reminderMinutesOfDay: minutes
        )
    }

    private func plan(for medication: MedicationEntry) -> ReminderPlan {
        NotificationManager.plan(for: medication, asOf: testToday, calendar: testCalendar)
    }

    /// The bug: a course with an end date scheduled a repeating trigger and kept firing
    /// forever, so a 10-day antibiotic course was still reminding a year later.
    @Test("A finished course schedules nothing")
    func finishedCourseSchedulesNothing() {
        let entry = medication(startDate: testDaysAgo(20), endDate: testDaysAgo(5))
        #expect(plan(for: entry) == .none)
    }

    @Test("A bounded course schedules dated reminders that expire on their own")
    func boundedCourseUsesDatedReminders() {
        // Ends in 4 days; today's 08:00 has passed relative to the reference date's midnight?
        // testToday is midnight, so today's 08:00 is still ahead and is included.
        let entry = medication(startDate: testDaysAgo(0), endDate: testDaysAhead(3))
        guard case .dated(let components) = plan(for: entry) else {
            Issue.record("expected dated reminders, got \(plan(for: entry))")
            return
        }
        #expect(components.count == 4)
        // Every one carries a full date, so it fires once and is gone.
        #expect(components.allSatisfy { $0.year != nil && $0.month != nil && $0.day != nil })
    }

    @Test("An open-ended course repeats daily")
    func openEndedCourseRepeats() {
        #expect(plan(for: medication(endDate: nil)) == .repeatingDaily(minutes: [480]))
    }

    @Test("Reminders switched off schedule nothing")
    func disabledSchedulesNothing() {
        #expect(plan(for: medication(reminderEnabled: false)) == .none)
    }

    @Test("No reminder times means nothing to schedule")
    func noTimesSchedulesNothing() {
        #expect(plan(for: medication(minutes: [])) == .none)
    }

    /// iOS caps pending notifications at 64 per app, so a long course must not try to claim
    /// them all — it falls back to a repeating reminder instead.
    @Test("A very long course falls back to repeating rather than flooding the queue")
    func longCourseFallsBackToRepeating() {
        let entry = medication(minutes: [8 * 60, 20 * 60], startDate: testDaysAgo(0), endDate: testDaysAhead(120))
        #expect(plan(for: entry) == .repeatingDaily(minutes: [480, 1200]))
    }
}
