import Foundation
import Testing
@testable import JPouch

private let hydrationTarget = 2_000

/// Builds a run of unremarkable logged days as raw entries.
private func steadyEntries(
    days: Int,
    startingDaysAgo start: Int,
    outputPerDay: Int = 6,
    hydrationML: Int = 3_000
) -> (outputs: [OutputEntry], hydration: [HydrationEntry]) {
    var outputs: [OutputEntry] = []
    var hydration: [HydrationEntry] = []
    for offset in start..<(start + days) {
        let day = testDaysAgo(offset)
        for index in 0..<outputPerDay {
            outputs.append(OutputEntry(timestamp: day.addingTimeInterval(Double(index) * 600)))
        }
        hydration.append(HydrationEntry(timestamp: day.addingTimeInterval(3_600), volumeML: hydrationML))
    }
    return (outputs, hydration)
}

private func build(
    windowDays: Int = 30,
    outputs: [OutputEntry] = [],
    hydration: [HydrationEntry] = [],
    foods: [FoodEntry] = [],
    medications: [MedicationEntry] = []
) -> GIReport {
    ReportBuilder.build(
        windowDays: windowDays,
        outputs: outputs,
        hydration: hydration,
        foods: foods,
        medications: medications,
        stageName: "Adaptation",
        hydrationTargetML: hydrationTarget,
        asOf: testToday,
        calendar: testCalendar
    )
}

@Suite("ReportBuilder — window and aggregates")
struct ReportWindowTests {

    /// PRD acceptance is 30 days of data producing a report, so the window boundary matters.
    @Test("Only counts entries inside the requested window")
    func excludesEntriesOutsideWindow() {
        let inside = steadyEntries(days: 30, startingDaysAgo: 0)
        let outside = steadyEntries(days: 10, startingDaysAgo: 40)
        let report = build(
            windowDays: 30,
            outputs: inside.outputs + outside.outputs,
            hydration: inside.hydration + outside.hydration
        )
        #expect(report.daysLogged == 30)
        #expect(report.averageOutputPerDay == 6.0)
    }

    @Test("Reports the requested range and window length")
    func reportsRange() {
        let report = build(windowDays: 90)
        #expect(report.windowDays == 90)
        #expect(report.rangeEnd == testToday)
        #expect(report.rangeStart == testDaysAgo(89))
    }

    @Test("Handles an empty period without inventing numbers")
    func handlesNoData() {
        let report = build()
        #expect(report.hasAnyData == false)
        #expect(report.daysLogged == 0)
        #expect(report.averageOutputPerDay == nil)
        #expect(report.averageHydrationML == nil)
        #expect(report.flagEpisodes.isEmpty)
    }

    @Test("Counts only logged days toward the fluid goal")
    func countsHydrationGoalDays() {
        // 10 days at goal, 5 days under, 15 days with no fluids logged at all.
        let atGoal = steadyEntries(days: 10, startingDaysAgo: 0, hydrationML: 2_500)
        let under = steadyEntries(days: 5, startingDaysAgo: 10, hydrationML: 500)
        let unlogged = steadyEntries(days: 15, startingDaysAgo: 15)
        let report = build(
            outputs: atGoal.outputs + under.outputs + unlogged.outputs,
            hydration: atGoal.hydration + under.hydration
        )
        #expect(report.daysWithHydrationLogged == 15)
        #expect(report.daysMeetingHydrationTarget == 10)
    }

    @Test("Summarises symptoms across the window")
    func summarisesSymptoms() {
        let base = steadyEntries(days: 30, startingDaysAgo: 0)
        let extra = [
            OutputEntry(timestamp: testDaysAgo(1), blood: .streaks, pain: 4),
            OutputEntry(timestamp: testDaysAgo(1), hasUrgency: true, urgencySeverity: 3),
            OutputEntry(timestamp: testDaysAgo(2), isNight: true),
            OutputEntry(timestamp: testDaysAgo(2), isNight: true),
        ]
        let report = build(outputs: base.outputs + extra, hydration: base.hydration)
        #expect(report.daysWithBlood == 1)
        #expect(report.daysWithUrgency == 1)
        #expect(report.nightEpisodes == 2)
        #expect(report.highestPain == 4)
    }
}

@Suite("ReportBuilder — flags, medications and food context")
struct ReportContentTests {

    /// A sustained spike with blood after a settled baseline should show up as one episode.
    @Test("Collapses a sustained flare into a single episode")
    func collapsesFlareEpisode() {
        let baseline = steadyEntries(days: 30, startingDaysAgo: 3)
        var outputs = baseline.outputs
        for offset in 0..<3 {
            let day = testDaysAgo(offset)
            for index in 0..<12 {
                outputs.append(OutputEntry(timestamp: day.addingTimeInterval(Double(index) * 600), blood: .streaks))
            }
        }
        let report = build(windowDays: 30, outputs: outputs, hydration: baseline.hydration)
        let flares = report.flagEpisodes.filter { $0.kind == .flare }
        #expect(flares.count == 1)
        #expect(flares.first?.dayCount == 2)
    }

    @Test("Includes medications overlapping the window and excludes ones that ended before it")
    func filtersMedications() {
        let current = MedicationEntry(name: "Ciprofloxacin", isAntibiotic: true, startDate: testDaysAgo(5))
        let ended = MedicationEntry(name: "Old course", startDate: testDaysAgo(200), endDate: testDaysAgo(150))
        let spanning = MedicationEntry(name: "Loperamide", startDate: testDaysAgo(200), endDate: nil)
        let report = build(medications: [current, ended, spanning])
        let names = report.medications.map(\.name)
        #expect(names.contains("Ciprofloxacin"))
        #expect(names.contains("Loperamide"))
        #expect(names.contains("Old course") == false)
    }

    @Test("Lists no food context when nothing was flagged")
    func noFoodContextWithoutFlags() {
        let base = steadyEntries(days: 30, startingDaysAgo: 0)
        let foods = [FoodEntry(timestamp: testDaysAgo(1), foodDescription: "Popcorn")]
        let report = build(outputs: base.outputs, hydration: base.hydration, foods: foods)
        #expect(report.flagEpisodes.isEmpty)
        #expect(report.foodsBeforeFlags.isEmpty)
    }

    @Test("Attaches foods logged shortly before a flag, ignoring older ones")
    func attachesRecentFoodsToFlags() {
        let baseline = steadyEntries(days: 30, startingDaysAgo: 3)
        var outputs = baseline.outputs
        for offset in 0..<3 {
            let day = testDaysAgo(offset)
            for index in 0..<12 {
                outputs.append(OutputEntry(timestamp: day.addingTimeInterval(Double(index) * 600), blood: .streaks))
            }
        }
        let foods = [
            FoodEntry(timestamp: testDaysAgo(2), foodDescription: "Popcorn"),
            FoodEntry(timestamp: testDaysAgo(20), foodDescription: "Ancient history"),
        ]
        let report = build(windowDays: 30, outputs: outputs, hydration: baseline.hydration, foods: foods)
        let allFoods = report.foodsBeforeFlags.flatMap(\.foods)
        #expect(allFoods.contains("Popcorn"))
        #expect(allFoods.contains("Ancient history") == false)
    }
}

@MainActor
@Suite("Report PDF rendering")
struct ReportPDFTests {

    private func sampleReport() -> GIReport {
        let baseline = steadyEntries(days: 30, startingDaysAgo: 3)
        var outputs = baseline.outputs
        for offset in 0..<3 {
            let day = testDaysAgo(offset)
            for index in 0..<12 {
                outputs.append(
                    OutputEntry(
                        timestamp: day.addingTimeInterval(Double(index) * 600),
                        blood: .streaks,
                        pain: 3,
                        isNight: index == 0
                    )
                )
            }
        }
        return ReportBuilder.build(
            windowDays: 30,
            outputs: outputs,
            hydration: baseline.hydration,
            foods: [FoodEntry(timestamp: testDaysAgo(2), foodDescription: "Popcorn, salad, coffee")],
            medications: [MedicationEntry(name: "Ciprofloxacin", dosage: "500mg", schedule: "twice daily", isAntibiotic: true, startDate: testDaysAgo(4))],
            stageName: "Long-Term Maintenance",
            hydrationTargetML: hydrationTarget,
            asOf: testToday,
            calendar: testCalendar
        )
    }

    @Test("Produces a valid, non-trivial PDF")
    func producesPDF() throws {
        let data = try #require(ReportPDFRenderer.makePDF(for: sampleReport()))
        #expect(data.count > 2_000)
        // %PDF- magic number
        #expect(data.prefix(5) == Data("%PDF-".utf8))

        // Written out so the layout can be inspected rather than assumed correct.
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("jpouch-sample-report.pdf")
        try data.write(to: url)
        print("SAMPLE_PDF_PATH: \(url.path)")
    }

    @Test("Produces a PDF even with no data logged")
    func producesPDFWhenEmpty() throws {
        let empty = ReportBuilder.build(
            windowDays: 30,
            outputs: [], hydration: [], foods: [], medications: [],
            stageName: "Pre-Op",
            hydrationTargetML: hydrationTarget,
            asOf: testToday,
            calendar: testCalendar
        )
        let data = try #require(ReportPDFRenderer.makePDF(for: empty))
        #expect(data.prefix(5) == Data("%PDF-".utf8))
    }
}
