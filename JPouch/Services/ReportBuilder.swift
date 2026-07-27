import Foundation

/// Aggregates logged entries into a `GIReport` for a 30- or 90-day window.
///
/// Pure and date-injectable so the output is testable without a live clock.
enum ReportBuilder {

    /// How far back to gather foods logged before a flag. The PRD's food-reintroduction window
    /// is 12–72 hours; this uses the full 72 so nothing relevant is cut off.
    static let foodLookbackHours = 72

    static func build(
        windowDays: Int,
        outputs: [OutputEntry],
        hydration: [HydrationEntry],
        foods: [FoodEntry],
        medications: [MedicationEntry],
        stageName: String,
        hydrationTargetML: Int,
        asOf referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> GIReport {
        let rangeEnd = calendar.startOfDay(for: referenceDate)
        let rangeStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: rangeEnd) ?? rangeEnd
        let windowEndExclusive = calendar.date(byAdding: .day, value: 1, to: rangeEnd) ?? rangeEnd

        let outputsInWindow = outputs.filter { $0.timestamp >= rangeStart && $0.timestamp < windowEndExclusive }
        let hydrationInWindow = hydration.filter { $0.timestamp >= rangeStart && $0.timestamp < windowEndExclusive }

        let summaries = PatternAnalyzer.dailySummaries(
            outputs: outputsInWindow,
            hydration: hydrationInWindow,
            calendar: calendar
        )

        let dailyPoints = summaries.map { summary in
            GIReport.DailyPoint(
                date: summary.date,
                outputCount: summary.outputCount,
                hydrationML: summary.hydrationML,
                hasBlood: summary.hasBlood,
                hasHydrationLogged: summary.hasHydrationLogged
            )
        }

        let loggedOutputDays = summaries.filter { $0.outputCount > 0 }
        let averageOutput = mean(loggedOutputDays.map { Double($0.outputCount) })

        // Split the window by date rather than by number of logged days, so a gap in logging
        // doesn't shift what counts as "the first half" of the period.
        let midpoint = calendar.date(byAdding: .day, value: windowDays / 2, to: rangeStart) ?? rangeStart
        let firstHalf = mean(loggedOutputDays.filter { $0.date < midpoint }.map { Double($0.outputCount) })
        let secondHalf = mean(loggedOutputDays.filter { $0.date >= midpoint }.map { Double($0.outputCount) })

        let hydrationDays = summaries.filter(\.hasHydrationLogged)
        let averageHydration = mean(hydrationDays.map { Double($0.hydrationML) })
        let daysMeetingTarget = hydrationDays.filter { $0.hydrationML >= hydrationTargetML }.count

        let flagEpisodes = PatternAnalyzer.flagEpisodes(
            summaries: PatternAnalyzer.dailySummaries(outputs: outputs, hydration: hydration, calendar: calendar),
            hydrationTargetML: hydrationTargetML,
            from: rangeStart,
            to: rangeEnd,
            calendar: calendar
        )

        let activeMedications = medications
            .filter { medication in
                let started = medication.startDate < windowEndExclusive
                let stillRelevant = medication.endDate.map { $0 >= rangeStart } ?? true
                return started && stillRelevant
            }
            .sorted { $0.startDate > $1.startDate }
            .map { medication in
                GIReport.MedicationLine(
                    name: medication.name,
                    dosage: medication.dosage,
                    schedule: medication.schedule,
                    isAntibiotic: medication.isAntibiotic,
                    startDate: medication.startDate,
                    endDate: medication.endDate
                )
            }

        let foodsBeforeFlags: [GIReport.FoodContext] = flagEpisodes.compactMap { episode in
            guard let lookbackStart = calendar.date(byAdding: .hour, value: -foodLookbackHours, to: episode.start) else {
                return nil
            }
            let names = foods
                .filter { $0.timestamp >= lookbackStart && $0.timestamp <= episode.start }
                .sorted { $0.timestamp < $1.timestamp }
                .map(\.foodDescription)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard !names.isEmpty else { return nil }
            return GIReport.FoodContext(flagDate: episode.start, foods: names)
        }

        let daysWithUrgency = Set(
            outputsInWindow
                .filter(\.hasUrgency)
                .map { calendar.startOfDay(for: $0.timestamp) }
        ).count

        return GIReport(
            generatedAt: referenceDate,
            windowDays: windowDays,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            stageName: stageName,
            dailyPoints: dailyPoints,
            daysLogged: loggedOutputDays.count,
            averageOutputPerDay: averageOutput,
            outputFirstHalfAverage: firstHalf,
            outputSecondHalfAverage: secondHalf,
            hydrationTargetML: hydrationTargetML,
            averageHydrationML: averageHydration,
            daysMeetingHydrationTarget: daysMeetingTarget,
            daysWithHydrationLogged: hydrationDays.count,
            daysWithBlood: summaries.filter(\.hasBlood).count,
            daysWithUrgency: daysWithUrgency,
            nightEpisodes: outputsInWindow.filter(\.isNight).count,
            highestPain: outputsInWindow.map(\.pain).max() ?? 0,
            flagEpisodes: flagEpisodes,
            medications: activeMedications,
            foodsBeforeFlags: foodsBeforeFlags
        )
    }

    private static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
