import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private(set) var isAuthorized = false

    private let waterType = HKQuantityType(.dietaryWater)
    private let bodyMassType = HKQuantityType(.bodyMass)

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthDataAvailable else { return }
        let toShare: Set<HKSampleType> = [waterType]
        let toRead: Set<HKObjectType> = [waterType, bodyMassType]
        do {
            try await store.requestAuthorization(toShare: toShare, read: toRead)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// Writes a water intake sample to HealthKit and returns its sample UUID.
    @discardableResult
    func logWater(volumeML: Int, date: Date = .now) async throws -> UUID {
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(volumeML))
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)
        try await store.save(sample)
        return sample.uuid
    }

    func latestBodyMassKG() async throws -> Double? {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: bodyMassType)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        let samples = try await descriptor.result(for: store)
        return samples.first?.quantity.doubleValue(for: .gramUnit(with: .kilo))
    }
}
