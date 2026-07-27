import SwiftUI
import Charts

/// One block of report content. Sections are measured individually so pagination can avoid
/// splitting a block across a page break.
struct ReportSection: Identifiable {
    let id = UUID()
    let view: AnyView

    init(@ViewBuilder _ content: () -> some View) {
        self.view = AnyView(content())
    }
}

enum ReportDocument {

    static func sections(for report: GIReport) -> [ReportSection] {
        var sections: [ReportSection] = [
            ReportSection { HeaderSection(report: report) },
            ReportSection { AtAGlanceSection(report: report) },
        ]

        if report.hasAnyData {
            sections.append(ReportSection { OutputSection(report: report) })
            sections.append(ReportSection { HydrationSection(report: report) })
            sections.append(ReportSection { SymptomsSection(report: report) })
        }

        sections.append(ReportSection { FlagsSection(report: report) })

        if !report.medications.isEmpty {
            sections.append(ReportSection { MedicationsSection(report: report) })
        }
        if !report.foodsBeforeFlags.isEmpty {
            sections.append(ReportSection { FoodContextSection(report: report) })
        }

        sections.append(ReportSection { DisclaimerSection() })
        return sections
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()
}

// MARK: - Page

struct ReportPage: View {
    let sections: [ReportSection]
    let pageNumber: Int
    let pageCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: ReportLayout.sectionSpacing) {
            ForEach(sections) { section in
                section.view
            }
            Spacer(minLength: 0)
            HStack {
                Text("J-Pouch")
                Spacer()
                Text("Page \(pageNumber) of \(pageCount)")
            }
            .font(.system(size: 8))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .environment(\.colorScheme, .light)
    }
}

enum ReportLayout {
    static let sectionSpacing: CGFloat = 16
}

// MARK: - Sections

private struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }
}

private struct HeaderSection: View {
    let report: GIReport

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("J-Pouch Summary")
                .font(.system(size: 22, weight: .bold))
            Text("\(ReportDocument.dateFormatter.string(from: report.rangeStart)) – \(ReportDocument.dateFormatter.string(from: report.rangeEnd))  ·  \(report.windowDays) days")
                .font(.system(size: 11))
            Text("Current stage: \(report.stageName)  ·  Generated \(ReportDocument.dateFormatter.string(from: report.generatedAt))")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Divider().padding(.top, 4)
        }
    }
}

private struct AtAGlanceSection: View {
    let report: GIReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "At a glance")
            if report.hasAnyData {
                HStack(alignment: .top, spacing: 12) {
                    Stat(label: "Avg output/day", value: format(report.averageOutputPerDay))
                    Stat(label: "Days logged", value: "\(report.daysLogged) of \(report.windowDays)")
                    Stat(label: "Avg fluids/day", value: report.averageHydrationML.map { "\(Int($0).formatted()) mL" } ?? "—")
                    Stat(label: "Days at fluid goal", value: "\(report.daysMeetingHydrationTarget) of \(report.daysWithHydrationLogged)")
                }
            } else {
                Text("No entries were logged in this period.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func format(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—"
    }

    private struct Stat: View {
        let label: String
        let value: String

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 15, weight: .semibold))
                Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct OutputSection: View {
    let report: GIReport

    private var trendDescription: String? {
        guard let first = report.outputFirstHalfAverage, let second = report.outputSecondHalfAverage else {
            return nil
        }
        let delta = second - first
        let firstText = first.formatted(.number.precision(.fractionLength(1)))
        let secondText = second.formatted(.number.precision(.fractionLength(1)))
        if abs(delta) < 0.5 {
            return "Roughly steady across the period (\(firstText) → \(secondText) per day)."
        }
        let direction = delta > 0 ? "higher" : "lower"
        return "Second half ran \(direction) than the first (\(firstText) → \(secondText) per day)."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "Output per day")
            Chart(report.dailyPoints) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Count", point.outputCount)
                )
                .foregroundStyle(point.hasBlood ? Color.red.opacity(0.75) : Color.accentColor.opacity(0.75))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 110)
            if let trendDescription {
                Text(trendDescription).font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Text("Red bars mark days where blood was logged.")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }
}

private struct HydrationSection: View {
    let report: GIReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "Fluid intake per day")
            Chart {
                ForEach(report.dailyPoints.filter(\.hasHydrationLogged)) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("mL", point.hydrationML)
                    )
                    .foregroundStyle(Color.blue.opacity(0.7))
                }
                RuleMark(y: .value("Target", report.hydrationTargetML))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(.gray)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 110)
            Text("Dashed line is the personal daily goal of \(report.hydrationTargetML) mL. Only days with fluids logged are shown.")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SymptomsSection: View {
    let report: GIReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "Symptoms logged")
            HStack(alignment: .top, spacing: 12) {
                Item(label: "Days with blood", value: "\(report.daysWithBlood)")
                Item(label: "Days with urgency", value: "\(report.daysWithUrgency)")
                Item(label: "Night episodes", value: "\(report.nightEpisodes)")
                Item(label: "Highest pain", value: "\(report.highestPain) of 5")
            }
        }
    }

    private struct Item: View {
        let label: String
        let value: String

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 13, weight: .semibold))
                Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FlagsSection: View {
    let report: GIReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "Pattern flags raised")
            if report.flagEpisodes.isEmpty {
                Text("None during this period.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(report.flagEpisodes, id: \.start) { episode in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(episode.kind.displayName) — \(range(for: episode)) (\(episode.dayCount) day\(episode.dayCount == 1 ? "" : "s"))")
                                .font(.system(size: 10, weight: .medium))
                            Text(explanation(for: episode.kind))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func range(for episode: PatternAnalyzer.FlagEpisode) -> String {
        let start = ReportDocument.shortDateFormatter.string(from: episode.start)
        guard episode.dayCount > 1 else { return start }
        return "\(start) – \(ReportDocument.shortDateFormatter.string(from: episode.end))"
    }

    private func explanation(for kind: PatternAnalyzer.FlagKind) -> String {
        switch kind {
        case .dehydration:
            "Output above this person's own baseline while logged fluids stayed below their daily goal."
        case .flare:
            "Output at least 50% above this person's own 30-day baseline, with blood logged."
        }
    }
}

private struct MedicationsSection: View {
    let report: GIReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "Medications in this period")
            ForEach(report.medications) { medication in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(line(for: medication)).font(.system(size: 10, weight: .medium))
                        Text(dates(for: medication)).font(.system(size: 8)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func line(for medication: GIReport.MedicationLine) -> String {
        var parts = [medication.name]
        if !medication.dosage.isEmpty { parts.append(medication.dosage) }
        if !medication.schedule.isEmpty { parts.append(medication.schedule) }
        if medication.isAntibiotic { parts.append("(antibiotic course)") }
        return parts.joined(separator: " · ")
    }

    private func dates(for medication: GIReport.MedicationLine) -> String {
        let start = ReportDocument.dateFormatter.string(from: medication.startDate)
        guard let end = medication.endDate else { return "Started \(start), ongoing" }
        return "\(start) – \(ReportDocument.dateFormatter.string(from: end))"
    }
}

private struct FoodContextSection: View {
    let report: GIReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "Foods logged before a flag")
            Text("Listed for context only. J-Pouch has not established any link between these foods and the flag — it simply shows what was logged in the \(ReportBuilder.foodLookbackHours) hours beforehand.")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
            ForEach(report.foodsBeforeFlags) { context in
                VStack(alignment: .leading, spacing: 1) {
                    Text("Before \(ReportDocument.shortDateFormatter.string(from: context.flagDate))")
                        .font(.system(size: 9, weight: .medium))
                    Text(context.foods.joined(separator: ", "))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct DisclaimerSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("This summary reports only what was logged in the J-Pouch app and how it compares to this person's own recent baseline. It is not a diagnosis, a clinical assessment, or a medical record, and the app's pattern flags are not validated clinical tools. Figures depend entirely on how consistently entries were logged.")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }
}
