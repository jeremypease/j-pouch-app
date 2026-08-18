import Foundation

enum Stage: String, Codable, CaseIterable, Identifiable, Hashable {
    case preOp
    case stagedSurgery
    case adaptation
    case longTermMaintenance

    var id: String { rawValue }

    /// Adaptation runs the first year after takedown, matching the PRD's ~6–12 month window.
    static let adaptationWindowMonths = 12

    /// Infers the stage from surgery dates, or nil if neither date has been entered yet.
    static func derived(stagedSurgeryDate: Date?, takedownDate: Date?, asOf referenceDate: Date = .now) -> Stage? {
        guard stagedSurgeryDate != nil || takedownDate != nil else { return nil }

        if let takedownDate, takedownDate <= referenceDate {
            let months = Calendar.current.dateComponents([.month], from: takedownDate, to: referenceDate).month ?? 0
            return months >= adaptationWindowMonths ? .longTermMaintenance : .adaptation
        }
        if let stagedSurgeryDate, stagedSurgeryDate <= referenceDate {
            return .stagedSurgery
        }
        // Dates are entered but still in the future.
        return .preOp
    }

    /// Whether to store an explicit override for someone who picked `picked` and supplied
    /// these dates.
    ///
    /// Returns nil when the dates already derive to the stage they chose, so the app can keep
    /// itself up to date as time passes. Returns their choice when the dates say something
    /// different or there are no dates at all — an explicit answer beats an inference, and
    /// with no dates there is nothing to infer from.
    static func override(
        forPicked picked: Stage,
        stagedSurgeryDate: Date?,
        takedownDate: Date?,
        asOf referenceDate: Date = .now
    ) -> Stage? {
        let derived = derived(
            stagedSurgeryDate: stagedSurgeryDate,
            takedownDate: takedownDate,
            asOf: referenceDate
        )
        return derived == picked ? nil : picked
    }

    /// Which surgery date onboarding should ask about for this stage.
    enum SurgeryDate {
        case stagedSurgery
        case takedown
    }

    var promptedDate: SurgeryDate {
        switch self {
        case .preOp, .stagedSurgery: .stagedSurgery
        case .adaptation, .longTermMaintenance: .takedown
        }
    }

    var promptedDateLabel: String {
        switch self {
        case .preOp: "Scheduled surgery date"
        case .stagedSurgery: "Date of your first surgery"
        case .adaptation: "Takedown date"
        case .longTermMaintenance: "Takedown date"
        }
    }

    var displayName: String {
        switch self {
        case .preOp: "Pre-op"
        case .stagedSurgery: "Staged surgery"
        case .adaptation: "Adaptation"
        case .longTermMaintenance: "Long-term maintenance"
        }
    }

    var summary: String {
        switch self {
        case .preOp:
            "Surgery is scheduled or being planned."
        case .stagedSurgery:
            "Between staged surgeries, before takedown."
        case .adaptation:
            "First months after takedown, output and diet are still settling."
        case .longTermMaintenance:
            "Years out — watching for pouchitis patterns and long-term trends."
        }
    }
}
