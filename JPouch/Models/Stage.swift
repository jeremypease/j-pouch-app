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

    var displayName: String {
        switch self {
        case .preOp: "Pre-Op"
        case .stagedSurgery: "Staged Surgery"
        case .adaptation: "Adaptation"
        case .longTermMaintenance: "Long-Term Maintenance"
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
