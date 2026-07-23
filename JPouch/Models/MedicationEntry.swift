import Foundation
import SwiftData

@Model
final class MedicationEntry {
    var id: UUID = UUID()
    var name: String = ""
    var dosage: String = ""
    var schedule: String = ""
    var isAntibiotic: Bool = false
    var startDate: Date = Date.now
    var endDate: Date?
    var reminderEnabled: Bool = false
    /// Times of day to remind, as minutes since midnight (0–1439), local time.
    var reminderMinutesOfDay: [Int] = []

    init(
        name: String,
        dosage: String = "",
        schedule: String = "",
        isAntibiotic: Bool = false,
        startDate: Date = .now,
        endDate: Date? = nil,
        reminderEnabled: Bool = false,
        reminderMinutesOfDay: [Int] = []
    ) {
        self.name = name
        self.dosage = dosage
        self.schedule = schedule
        self.isAntibiotic = isAntibiotic
        self.startDate = startDate
        self.endDate = endDate
        self.reminderEnabled = reminderEnabled
        self.reminderMinutesOfDay = reminderMinutesOfDay
    }
}
