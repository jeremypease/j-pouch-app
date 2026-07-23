import Foundation
import SwiftData

/// Loosely adapted from the Bristol Stool Scale for pouch output, which tends to run looser
/// than typical stool by nature. Not a validated clinical scale — a mid-range reading is a
/// common, unremarkable baseline for many pouch patients, not necessarily a problem.
enum PouchConsistency {
    static let labels: [Int: String] = [
        1: "Very firm, hard to pass",
        2: "Firm, formed",
        3: "Soft, formed",
        4: "Soft, loose — common baseline",
        5: "Loose, little form",
        6: "Watery, thin",
        7: "Entirely liquid",
    ]

    static func label(for level: Int) -> String {
        labels[level] ?? ""
    }
}

enum BloodLevel: String, Codable, CaseIterable, Identifiable {
    case none, streaks, significant
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .none: "None"
        case .streaks: "Streaks"
        case .significant: "Significant"
        }
    }
}

@Model
final class OutputEntry {
    var timestamp: Date = Date.now
    /// Pouch-adapted consistency scale, 1 (very loose/watery) – 7 (formed).
    var consistency: Int = 4
    var hasUrgency: Bool = false
    /// 0–5, only meaningful when hasUrgency is true.
    var urgencySeverity: Int = 0
    var bloodRawValue: String = BloodLevel.none.rawValue
    /// 0–5 pain scale.
    var pain: Int = 0
    var isNight: Bool = false
    var notes: String?

    var blood: BloodLevel {
        get { BloodLevel(rawValue: bloodRawValue) ?? .none }
        set { bloodRawValue = newValue.rawValue }
    }

    init(
        timestamp: Date = .now,
        consistency: Int = 4,
        hasUrgency: Bool = false,
        urgencySeverity: Int = 0,
        blood: BloodLevel = .none,
        pain: Int = 0,
        isNight: Bool = false,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.consistency = consistency
        self.hasUrgency = hasUrgency
        self.urgencySeverity = urgencySeverity
        self.bloodRawValue = blood.rawValue
        self.pain = pain
        self.isNight = isNight
        self.notes = notes
    }
}
