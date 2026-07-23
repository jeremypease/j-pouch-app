import Foundation
import SwiftData

enum HydrationKind: String, Codable, CaseIterable, Identifiable {
    case water, electrolyte
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .water: "Water"
        case .electrolyte: "Electrolyte"
        }
    }
}

@Model
final class HydrationEntry {
    var timestamp: Date = Date.now
    var volumeML: Int = 0
    var kindRawValue: String = HydrationKind.water.rawValue
    /// Set once this entry has been mirrored into HealthKit.
    var healthKitSampleID: String?

    var kind: HydrationKind {
        get { HydrationKind(rawValue: kindRawValue) ?? .water }
        set { kindRawValue = newValue.rawValue }
    }

    init(timestamp: Date = .now, volumeML: Int, kind: HydrationKind = .water) {
        self.timestamp = timestamp
        self.volumeML = volumeML
        self.kindRawValue = kind.rawValue
    }
}
