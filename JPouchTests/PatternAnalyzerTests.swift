import Foundation
import Testing
@testable import JPouch

private typealias Summary = PatternAnalyzer.DailySummary

/// A run of unremarkable days to establish a personal baseline.
private func baselineDays(
    count: Int = 30,
    startingDaysAgo start: Int,
    outputPerDay: Int = 6,
    hydrationML: Int = 3_000
) -> [Summary] {
    (start..<(start + count)).map { offset in
        Summary(
            date: testDaysAgo(offset),
            outputCount: outputPerDay,
            hydrationML: hydrationML,
            hasHydrationLogged: true,
            hasBlood: false
        )
    }
}

private let hydrationTarget = 2_000

private func analyze(_ summaries: [Summary]) -> PatternAnalyzer.Analysis {
    PatternAnalyzer.analyze(
        summaries: summaries,
        hydrationTargetML: hydrationTarget,
        asOf: testToday,
        calendar: testCalendar
    )
}

@Suite("PatternAnalyzer — dehydration flag")
struct DehydrationFlagTests {

    /// PRD acceptance: 3+ days of output above baseline with hydration below target.
    @Test("Flags after 3 consecutive days of elevated output and below-target hydration")
    func flagsOnThreeQualifyingDays() {
        let recent = (0..<3).map { offset in
            Summary(
                date: testDaysAgo(offset),
                outputCount: 9,
                hydrationML: 1_000,
                hasHydrationLogged: true
            )
        }
        let analysis = analyze(baselineDays(startingDaysAgo: 3) + recent)
        #expect(analysis.dehydration == .flagged(consecutiveDays: 3))
    }

    @Test("Does not flag when the pattern has only held for 2 days")
    func doesNotFlagBelowThreshold() {
        let recent = (0..<2).map { offset in
            Summary(date: testDaysAgo(offset), outputCount: 9, hydrationML: 1_000, hasHydrationLogged: true)
        }
        let normal = [Summary(date: testDaysAgo(2), outputCount: 6, hydrationML: 3_000, hasHydrationLogged: true)]
        let analysis = analyze(baselineDays(startingDaysAgo: 3) + normal + recent)
        #expect(analysis.dehydration == .steady)
    }

    /// Someone who logs output diligently but fluids only sometimes should not get flagged
    /// for dehydration — an unlogged day is not evidence of not drinking.
    @Test("Does not flag when hydration simply wasn't logged")
    func doesNotFlagOnUnloggedHydration() {
        let recent = (0..<3).map { offset in
            Summary(date: testDaysAgo(offset), outputCount: 9, hydrationML: 0, hasHydrationLogged: false)
        }
        let analysis = analyze(baselineDays(startingDaysAgo: 3) + recent)
        #expect(analysis.dehydration == .steady)
    }

    @Test("Does not flag when hydration meets target despite elevated output")
    func doesNotFlagWhenHydrated() {
        let recent = (0..<3).map { offset in
            Summary(date: testDaysAgo(offset), outputCount: 9, hydrationML: 3_500, hasHydrationLogged: true)
        }
        let analysis = analyze(baselineDays(startingDaysAgo: 3) + recent)
        #expect(analysis.dehydration == .steady)
    }
}

@Suite("PatternAnalyzer — flare flag")
struct FlareFlagTests {

    /// PRD acceptance: output spikes 50%+ over the 30-day baseline with blood, for 2+ days.
    @Test("Flags after 2 consecutive days of a 50%+ spike with blood present")
    func flagsOnTwoQualifyingDays() {
        let recent = (0..<2).map { offset in
            Summary(
                date: testDaysAgo(offset),
                outputCount: 9, // baseline 6 * 1.5
                hydrationML: 3_000,
                hasHydrationLogged: true,
                hasBlood: true
            )
        }
        let analysis = analyze(baselineDays(startingDaysAgo: 2) + recent)
        #expect(analysis.flare == .flagged(consecutiveDays: 2))
    }

    @Test("Does not flag a spike without blood")
    func doesNotFlagSpikeAlone() {
        let recent = (0..<2).map { offset in
            Summary(date: testDaysAgo(offset), outputCount: 12, hydrationML: 3_000, hasHydrationLogged: true, hasBlood: false)
        }
        let analysis = analyze(baselineDays(startingDaysAgo: 2) + recent)
        #expect(analysis.flare == .steady)
    }

    @Test("Does not flag blood without a frequency spike")
    func doesNotFlagBloodAlone() {
        let recent = (0..<2).map { offset in
            Summary(date: testDaysAgo(offset), outputCount: 6, hydrationML: 3_000, hasHydrationLogged: true, hasBlood: true)
        }
        let analysis = analyze(baselineDays(startingDaysAgo: 2) + recent)
        #expect(analysis.flare == .steady)
    }

    @Test("Does not flag when the pattern has only held for 1 day")
    func doesNotFlagSingleDay() {
        let recent = [
            Summary(date: testDaysAgo(0), outputCount: 12, hydrationML: 3_000, hasHydrationLogged: true, hasBlood: true),
            Summary(date: testDaysAgo(1), outputCount: 6, hydrationML: 3_000, hasHydrationLogged: true, hasBlood: false),
        ]
        let analysis = analyze(baselineDays(startingDaysAgo: 2) + recent)
        #expect(analysis.flare == .steady)
    }
}

@Suite("PatternAnalyzer — guards against false alarms")
struct PatternGuardTests {

    @Test("Reports building-baseline rather than flagging without enough history")
    func requiresMinimumHistory() {
        let recent = (0..<3).map { offset in
            Summary(
                date: testDaysAgo(offset),
                outputCount: 20,
                hydrationML: 100,
                hasHydrationLogged: true,
                hasBlood: true
            )
        }
        let analysis = analyze(recent)
        #expect(analysis.dehydration == .buildingBaseline(loggedDays: 3, daysNeeded: PatternAnalyzer.minimumBaselineDays))
        #expect(analysis.flare == .buildingBaseline(loggedDays: 3, daysNeeded: PatternAnalyzer.minimumBaselineDays))
        #expect(analysis.baselineOutputPerDay == nil)
    }

    /// A gap means we don't know what happened, so the streak shouldn't carry across it.
    @Test("A day with no logging breaks the streak instead of being skipped")
    func gapBreaksStreak() {
        let recent = [
            Summary(date: testDaysAgo(0), outputCount: 9, hydrationML: 1_000, hasHydrationLogged: true),
            // testDaysAgo(1) deliberately absent
            Summary(date: testDaysAgo(2), outputCount: 9, hydrationML: 1_000, hasHydrationLogged: true),
        ]
        let analysis = analyze(baselineDays(startingDaysAgo: 3) + recent)
        #expect(analysis.dehydration == .steady)
    }

    /// If the baseline window included the days being evaluated, a large spike would drag its
    /// own baseline upward and partially mask itself.
    @Test("Baseline excludes the days being evaluated, so a spike can't mask itself")
    func baselineExcludesEvaluationWindow() {
        let recent = (0..<2).map { offset in
            Summary(date: testDaysAgo(offset), outputCount: 30, hydrationML: 3_000, hasHydrationLogged: true, hasBlood: true)
        }
        let analysis = analyze(baselineDays(startingDaysAgo: 2, outputPerDay: 6) + recent)
        #expect(analysis.baselineOutputPerDay == 6.0)
        #expect(analysis.flare == .flagged(consecutiveDays: 2))
    }

    @Test("Steady logging at a high but consistent personal baseline is not flagged")
    func highButStablePersonalBaselineIsNormal() {
        // 12 stools/day every day is a lot in absolute terms, but if it's this person's
        // normal it is not a pattern change and must not fire.
        let steady = baselineDays(count: 32, startingDaysAgo: 0, outputPerDay: 12)
        let analysis = analyze(steady)
        #expect(analysis.dehydration == .steady)
        #expect(analysis.flare == .steady)
    }
}

@Suite("PatternAnalyzer — daily summaries")
struct DailySummaryTests {

    @Test("Groups entries by calendar day and records blood presence")
    func groupsByDay() throws {
        let outputs = [
            OutputEntry(timestamp: testDaysAgo(0).addingTimeInterval(3_600), blood: .none),
            OutputEntry(timestamp: testDaysAgo(0).addingTimeInterval(7_200), blood: .streaks),
            OutputEntry(timestamp: testDaysAgo(1).addingTimeInterval(3_600), blood: .none),
        ]
        let hydration = [
            HydrationEntry(timestamp: testDaysAgo(0).addingTimeInterval(3_600), volumeML: 500),
            HydrationEntry(timestamp: testDaysAgo(0).addingTimeInterval(7_200), volumeML: 250),
        ]

        let summaries = PatternAnalyzer.dailySummaries(outputs: outputs, hydration: hydration, calendar: testCalendar)

        #expect(summaries.count == 2)

        let mostRecent = try #require(summaries.last)
        #expect(mostRecent.outputCount == 2)
        #expect(mostRecent.hydrationML == 750)
        #expect(mostRecent.hasHydrationLogged)
        #expect(mostRecent.hasBlood)

        let earlier = try #require(summaries.first)
        #expect(earlier.outputCount == 1)
        #expect(earlier.hasHydrationLogged == false)
        #expect(earlier.hasBlood == false)
    }

    @Test("Days with no entries are absent rather than counted as zero-output days")
    func skipsUnloggedDays() {
        let outputs = [OutputEntry(timestamp: testDaysAgo(0)), OutputEntry(timestamp: testDaysAgo(5))]
        let summaries = PatternAnalyzer.dailySummaries(outputs: outputs, hydration: [], calendar: testCalendar)
        #expect(summaries.count == 2)
    }
}
