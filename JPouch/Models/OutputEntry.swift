import Foundation
import SwiftData

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
    var timestamp: Date
    /// Pouch-adapted consistency scale, 1 (very loose/watery) – 7 (formed).
    var consistency: Int
    var hasUrgency: Bool
    /// 0–5, only meaningful when hasUrgency is true.
    var urgencySeverity: Int
    var bloodRawValue: String
    /// 0–5 pain scale.
    var pain: Int
    var isNight: Bool
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
