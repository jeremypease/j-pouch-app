import Foundation
import HealthKit

/// A medication read from the Health app's Medications feature (iOS 26+ only, read-only).
struct HealthMedication: Identifiable {
    let id = UUID()
    let name: String
    let nickname: String?
    let isArchived: Bool
    let hasSchedule: Bool
}

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

    // MARK: - Medications (iOS 26+)
    //
    // Apple's HealthKit Medications API (HKUserAnnotatedMedication) is read-only for
    // third-party apps and only available on iOS 26+. Medications themselves are only ever
    // added or edited in the Health app; J-Pouch just reads and displays them. All
    // availability checks live here so the rest of the app never needs `#available`.

    var supportsMedicationsAPI: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    func requestMedicationsAuthorization() async {
        guard #available(iOS 26.0, *), isHealthDataAvailable else { return }
        // Medications require per-object authorization (like clinical records / vision
        // prescriptions) rather than the standard bulk requestAuthorization(toShare:read:) —
        // the user picks which individual medications to share from a system prompt.
        _ = try? await store.requestPerObjectReadAuthorization(for: HKObjectType.userAnnotatedMedicationType(), predicate: nil)
    }

    func fetchMedications() async throws -> [HealthMedication] {
        guard #available(iOS 26.0, *) else { return [] }
        return try await withCheckedThrowingContinuation { continuation in
            var results: [HealthMedication] = []
            let query = HKUserAnnotatedMedicationQuery(predicate: nil, limit: HKObjectQueryNoLimit) { _, medication, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let medication {
                    results.append(HealthMedication(
                        name: medication.medication.displayText,
                        nickname: medication.nickname,
                        isArchived: medication.isArchived,
                        hasSchedule: medication.hasSchedule
                    ))
                }
                if done {
                    continuation.resume(returning: results)
                }
            }
            store.execute(query)
        }
    }
}
