import Foundation
import SwiftData

@Model
final class FoodEntry {
    var timestamp: Date
    var foodDescription: String
    var photoData: Data?
    var notes: String?

    init(timestamp: Date = .now, foodDescription: String, photoData: Data? = nil, notes: String? = nil) {
        self.timestamp = timestamp
        self.foodDescription = foodDescription
        self.photoData = photoData
        self.notes = notes
    }
}
