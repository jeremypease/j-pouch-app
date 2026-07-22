import Foundation

enum Stage: String, Codable, CaseIterable, Identifiable {
    case preOp
    case stagedSurgery
    case adaptation
    case longTermMaintenance

    var id: String { rawValue }

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
