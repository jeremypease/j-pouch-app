import Foundation
import SwiftData

@Model
final class MedicationEntry {
    var name: String
    var dosage: String
    var schedule: String
    var isAntibiotic: Bool
    var startDate: Date
    var endDate: Date?

    init(
        name: String,
        dosage: String = "",
        schedule: String = "",
        isAntibiotic: Bool = false,
        startDate: Date = .now,
        endDate: Date? = nil
    ) {
        self.name = name
        self.dosage = dosage
        self.schedule = schedule
        self.isAntibiotic = isAntibiotic
        self.startDate = startDate
        self.endDate = endDate
    }
}
