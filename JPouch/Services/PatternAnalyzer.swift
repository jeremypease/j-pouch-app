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

    enum FlagKind: String, Equatable {
        case dehydration
        case flare

        var displayName: String {
            switch self {
            case .dehydration: "Hydration"
            case .flare: "Pattern change"
            }
        }
    }

    /// A consecutive run of days on which a flag would have been showing.
    struct FlagEpisode: Identifiable, Equatable {
        var kind: FlagKind
        var start: Date
        var end: Date
        var dayCount: Int

        /// A dehydration and a flare episode can legitimately begin on the same day, so the
        /// start date alone is not a usable identity. Kind plus start is unique, since one
        /// kind cannot have two episodes starting on the same day. Derived rather than a
        /// stored UUID so the type keeps value equality.
        var id: String { "\(kind.rawValue)-\(start.timeIntervalSince1970)" }
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

        let dehydration = evaluate(
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

        let flare = evaluate(
            byDay: byDay,
            today: today,
            calendar: calendar,
            requiredDays: flareConsecutiveDays
        ) { summary, baseline in
            Double(summary.outputCount) >= baseline * flareSpikeMultiplier && summary.hasBlood
        }

        return Analysis(
            dehydration: dehydration.status,
            flare: flare.status,
            baselineOutputPerDay: flare.baseline ?? dehydration.baseline
        )
    }

    // MARK: - History

    /// Replays the analysis day by day across a window to find when flags would have been
    /// showing, collapsing consecutive days into episodes.
    ///
    /// Each day is evaluated using only the data available up to that day, so this reflects
    /// what the person would actually have seen at the time rather than hindsight.
    static func flagEpisodes(
        summaries: [DailySummary],
        hydrationTargetML: Int,
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .current
    ) -> [FlagEpisode] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return [] }

        var flaggedDays: [(day: Date, kind: FlagKind)] = []
        var day = start
        while day <= end {
            let priorSummaries = summaries.filter { calendar.startOfDay(for: $0.date) <= day }
            let analysis = analyze(
                summaries: priorSummaries,
                hydrationTargetML: hydrationTargetML,
                asOf: day,
                calendar: calendar
            )
            if case .flagged = analysis.flare {
                flaggedDays.append((day, .flare))
            }
            if case .flagged = analysis.dehydration {
                flaggedDays.append((day, .dehydration))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        return collapseIntoEpisodes(flaggedDays, calendar: calendar)
    }

    private static func collapseIntoEpisodes(
        _ flaggedDays: [(day: Date, kind: FlagKind)],
        calendar: Calendar
    ) -> [FlagEpisode] {
        var episodes: [FlagEpisode] = []

        for kind in [FlagKind.flare, .dehydration] {
            let days = flaggedDays.filter { $0.kind == kind }.map(\.day).sorted()
            var current: FlagEpisode?

            for day in days {
                if var episode = current,
                   let expectedNext = calendar.date(byAdding: .day, value: 1, to: episode.end),
                   calendar.isDate(day, inSameDayAs: expectedNext) {
                    episode.end = day
                    episode.dayCount += 1
                    current = episode
                } else {
                    if let episode = current { episodes.append(episode) }
                    current = FlagEpisode(kind: kind, start: day, end: day, dayCount: 1)
                }
            }
            if let episode = current { episodes.append(episode) }
        }

        return episodes.sorted { $0.start < $1.start }
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

    /// Finds the true length of a currently-active streak together with a baseline that's
    /// self-consistent with it.
    ///
    /// The naive version of this — count up to `requiredDays` and stop — can never report a
    /// streak longer than the threshold, so a flag that's been active for two weeks reads
    /// identically to one that started yesterday. Simply removing that cap isn't enough on its
    /// own, though: the baseline is computed by excluding a fixed number of recent days, and if
    /// the real streak runs longer than that exclusion window, the tail end of the streak
    /// leaks into the baseline average and starts dragging it upward — the exact self-masking
    /// the fixed window was originally there to prevent. So this alternates between counting
    /// the streak and widening the baseline's exclusion to match it until the two agree.
    private static func evaluate(
        byDay: [Date: DailySummary],
        today: Date,
        calendar: Calendar,
        requiredDays: Int,
        matches: (DailySummary, Double) -> Bool
    ) -> (status: PatternStatus, baseline: Double?) {
        var exclusion = requiredDays
        var streak = -1

        // Small fixed cap rather than looping until convergence: realistic data settles in 1-2
        // rounds (the streak either doesn't change, or grows to meet a wider exclusion window
        // that then doesn't move the baseline enough to change the streak again). Anything that
        // doesn't settle within this many rounds is pathological input, not a longer streak.
        for _ in 0..<8 {
            guard let baseline = baselineOutputPerDay(
                byDay: byDay,
                excludingMostRecentDays: exclusion,
                endingAt: today,
                calendar: calendar
            ) else {
                let logged = byDay.values.filter { $0.outputCount > 0 }.count
                return (.buildingBaseline(loggedDays: logged, daysNeeded: minimumBaselineDays), nil)
            }

            let newStreak = consecutiveMatchingDays(byDay: byDay, today: today, calendar: calendar) { summary in
                matches(summary, baseline)
            }

            if newStreak == streak {
                return (newStreak >= requiredDays ? .flagged(consecutiveDays: newStreak) : .steady, baseline)
            }
            streak = newStreak
            exclusion = max(streak, requiredDays)
        }

        let baseline = baselineOutputPerDay(
            byDay: byDay, excludingMostRecentDays: exclusion, endingAt: today, calendar: calendar
        )
        return (streak >= requiredDays ? .flagged(consecutiveDays: streak) : .steady, baseline)
    }

    /// Walks back from today counting consecutive days that satisfy `matches`. A day with no
    /// summary at all breaks the streak rather than being skipped — we don't flag across gaps
    /// in logging, since we can't know what happened on the missing days. Capped at 10 years so
    /// corrupted data can't spin this forever; no genuine streak runs anywhere near that long.
    private static func consecutiveMatchingDays(
        byDay: [Date: DailySummary],
        today: Date,
        calendar: Calendar,
        matches: (DailySummary) -> Bool
    ) -> Int {
        var streak = 0
        for offset in 0..<3_650 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let summary = byDay[day],
                  matches(summary)
            else { break }
            streak += 1
        }
        return streak
    }
}
