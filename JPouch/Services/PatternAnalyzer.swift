import Foundation

/// Rule-based (not ML) detection of dehydration and flare-like patterns in logged data.
///
/// Everything here is deliberately conservative. These flags exist to prompt a conversation
/// with a care team, never to diagnose, and a false alarm in a health-anxiety context has a
/// real cost — both to the person and to whether they keep trusting the flag at all. Where
/// the data is ambiguous, the analyzer declines to flag rather than guessing.
///
/// The logic is pure and calendar-injectable so it can be tested against the PRD's stated
/// acceptance criteria without SwiftData or a live clock.
enum PatternAnalyzer {

    // MARK: - Tuning

    /// Days of history used to establish a personal baseline.
    static let baselineWindowDays = 30
    /// Minimum *logged* days required before any flag is surfaced at all.
    static let minimumBaselineDays = 7
    /// Consecutive qualifying days before raising the dehydration flag.
    static let dehydrationConsecutiveDays = 3
    /// Consecutive qualifying days before raising the flare flag.
    static let flareConsecutiveDays = 2
    /// Output frequency multiple over baseline that counts as a flare-level spike (50%+ above).
    static let flareSpikeMultiplier = 1.5

    // MARK: - Types

    /// One calendar day's worth of logged activity.
    struct DailySummary: Equatable {
        /// Start of day, in the calendar used to build this summary.
        var date: Date
        var outputCount: Int
        var hydrationML: Int
        /// Whether *any* hydration was logged, distinct from having logged 0 mL. A day with no
        /// hydration entries means "didn't log," which is not evidence of not drinking.
        var hasHydrationLogged: Bool
        var hasBlood: Bool

        init(
            date: Date,
            outputCount: Int = 0,
            hydrationML: Int = 0,
            hasHydrationLogged: Bool = false,
            hasBlood: Bool = false
        ) {
            self.date = date
            self.outputCount = outputCount
            self.hydrationML = hydrationML
            self.hasHydrationLogged = hasHydrationLogged
            self.hasBlood = hasBlood
        }
    }

    enum PatternStatus: Equatable {
        /// Not enough logged history to say anything meaningful yet.
        case buildingBaseline(loggedDays: Int, daysNeeded: Int)
        /// Enough history, and nothing currently stands out.
        case steady
        /// The pattern has held for `consecutiveDays`.
        case flagged(consecutiveDays: Int)
    }

    struct Analysis: Equatable {
        var dehydration: PatternStatus
        var flare: PatternStatus
        /// Mean output entries per logged day over the baseline window, if establishable.
        var baselineOutputPerDay: Double?
    }

    // MARK: - Building summaries

    /// Collapses raw entries into one summary per calendar day that has activity.
    ///
    /// Days with no entries at all are simply absent rather than present-with-zero: for a pouch
    /// patient, zero logged output means the day wasn't logged, not that nothing happened.
    /// Treating unlogged days as genuine zeros would drag the baseline down and make ordinary
    /// days look like spikes.
    static func dailySummaries(
        outputs: [OutputEntry],
        hydration: [HydrationEntry],
        calendar: Calendar = .current
    ) -> [DailySummary] {
        var byDay: [Date: DailySummary] = [:]

        for output in outputs {
            let day = calendar.startOfDay(for: output.timestamp)
            var summary = byDay[day] ?? DailySummary(date: day)
            summary.outputCount += 1
            if output.blood != .none {
                summary.hasBlood = true
            }
            byDay[day] = summary
        }

        for entry in hydration {
            let day = calendar.startOfDay(for: entry.timestamp)
            var summary = byDay[day] ?? DailySummary(date: day)
            summary.hydrationML += entry.volumeML
            summary.hasHydrationLogged = true
            byDay[day] = summary
        }

        return byDay.values.sorted { $0.date < $1.date }
    }

    // MARK: - Analysis

    static func analyze(
        summaries: [DailySummary],
        hydrationTargetML: Int,
        asOf referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Analysis {
        let today = calendar.startOfDay(for: referenceDate)
        let byDay = Dictionary(uniqueKeysWithValues: summaries.map { (calendar.startOfDay(for: $0.date), $0) })

        // Each flag's baseline excludes its own evaluation window, so a spike can't quietly
        // inflate the very baseline it's being measured against and mask itself.
        let dehydrationBaseline = baselineOutputPerDay(
            byDay: byDay,
            excludingMostRecentDays: dehydrationConsecutiveDays,
            endingAt: today,
            calendar: calendar
        )
        let flareBaseline = baselineOutputPerDay(
            byDay: byDay,
            excludingMostRecentDays: flareConsecutiveDays,
            endingAt: today,
            calendar: calendar
        )

        let dehydration = status(
            baseline: dehydrationBaseline,
            byDay: byDay,
            today: today,
            calendar: calendar,
            requiredDays: dehydrationConsecutiveDays
        ) { summary, baseline in
            // Requires hydration to actually have been logged: an unlogged day is ambiguous,
            // and flagging on it would fire for anyone who tracks output but not fluids.
            summary.hasHydrationLogged
                && Double(summary.outputCount) > baseline
                && summary.hydrationML < hydrationTargetML
        }

        let flare = status(
            baseline: flareBaseline,
            byDay: byDay,
            today: today,
            calendar: calendar,
            requiredDays: flareConsecutiveDays
        ) { summary, baseline in
            Double(summary.outputCount) >= baseline * flareSpikeMultiplier && summary.hasBlood
        }

        return Analysis(
            dehydration: dehydration,
            flare: flare,
            baselineOutputPerDay: flareBaseline ?? dehydrationBaseline
        )
    }

    // MARK: - Internals

    /// Mean output per logged day over the baseline window, ignoring the most recent
    /// `excluded` days. Returns nil when there isn't enough logged history to be meaningful.
    private static func baselineOutputPerDay(
        byDay: [Date: DailySummary],
        excludingMostRecentDays excluded: Int,
        endingAt today: Date,
        calendar: Calendar
    ) -> Double? {
        var counts: [Int] = []
        for offset in excluded..<(excluded + baselineWindowDays) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let summary = byDay[day],
                  summary.outputCount > 0
            else { continue }
            counts.append(summary.outputCount)
        }
        guard counts.count >= minimumBaselineDays else { return nil }
        return Double(counts.reduce(0, +)) / Double(counts.count)
    }

    /// Walks back from today counting consecutive days that satisfy `matches`. A day with no
    /// summary at all breaks the streak rather than being skipped — we don't flag across gaps
    /// in logging, since we can't know what happened on the missing days.
    private static func status(
        baseline: Double?,
        byDay: [Date: DailySummary],
        today: Date,
        calendar: Calendar,
        requiredDays: Int,
        matches: (DailySummary, Double) -> Bool
    ) -> PatternStatus {
        guard let baseline else {
            let logged = byDay.values.filter { $0.outputCount > 0 }.count
            return .buildingBaseline(loggedDays: logged, daysNeeded: minimumBaselineDays)
        }

        var streak = 0
        for offset in 0..<requiredDays {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let summary = byDay[day],
                  matches(summary, baseline)
            else { break }
            streak += 1
        }

        return streak >= requiredDays ? .flagged(consecutiveDays: streak) : .steady
    }
}
