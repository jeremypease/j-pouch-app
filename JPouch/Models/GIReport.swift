import Foundation

/// A snapshot of logged data prepared for a GI appointment.
///
/// Purely descriptive: it reports what was logged and where the person's own patterns shifted.
/// It draws no clinical conclusions and deliberately avoids anything that reads as a finding.
struct GIReport: Equatable {

    struct DailyPoint: Identifiable, Equatable {
        var id: Date { date }
        var date: Date
        var outputCount: Int
        var hydrationML: Int
        var hasBlood: Bool
        var hasHydrationLogged: Bool
    }

    struct MedicationLine: Identifiable, Equatable {
        var id = UUID()
        var name: String
        var dosage: String
        var schedule: String
        var isAntibiotic: Bool
        var startDate: Date
        var endDate: Date?
    }

    /// Foods logged in the days leading up to a flag. Presented as context for a conversation,
    /// never as an implied cause — the app has not established any correlation.
    struct FoodContext: Identifiable, Equatable {
        var id = UUID()
        var flagDate: Date
        var foods: [String]
    }

    var generatedAt: Date
    var windowDays: Int
    var rangeStart: Date
    var rangeEnd: Date
    var stageName: String

    var dailyPoints: [DailyPoint]

    var daysLogged: Int
    var averageOutputPerDay: Double?
    /// Averages for the first and second half of the window, so a direction of travel is
    /// visible without claiming statistical significance.
    var outputFirstHalfAverage: Double?
    var outputSecondHalfAverage: Double?

    var hydrationTargetML: Int
    var averageHydrationML: Double?
    var daysMeetingHydrationTarget: Int
    var daysWithHydrationLogged: Int

    var daysWithBlood: Int
    var daysWithUrgency: Int
    var nightEpisodes: Int
    var highestPain: Int

    var flagEpisodes: [PatternAnalyzer.FlagEpisode]
    var medications: [MedicationLine]
    var foodsBeforeFlags: [FoodContext]

    var hasAnyData: Bool { daysLogged > 0 }
}
