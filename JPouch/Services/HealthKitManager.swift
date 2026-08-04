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

enum HealthConnectionState: Equatable {
    /// Not checked yet. Distinct from `notConnected` so the UI can stay quiet instead of
    /// asserting a state it hasn't verified — briefly flashing "Not connected" at someone who
    /// is connected is the exact bug this type exists to prevent.
    case unknown
    /// The device has no Health data (e.g. iPad without Health).
    case unavailable
    /// The person hasn't been through the permission flow yet.
    case notConnected
    /// The person has answered our permission request. Note this does *not* mean they granted
    /// everything — see the discussion on `refreshConnectionState()`.
    case connected
}

/// Main-actor isolated because its `@Observable` state drives SwiftUI. Without this, the
/// mutations in `refreshConnectionState()` happen on whatever executor the nonisolated async
/// method resumes on, which races with SwiftUI reading the same properties on the main thread.
/// The underlying HealthKit calls still do their work off the main thread themselves.
@MainActor
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    private let waterType = HKQuantityType(.dietaryWater)
    private let bodyMassType = HKQuantityType(.bodyMass)

    private var shareTypes: Set<HKSampleType> { [waterType] }
    private var readTypes: Set<HKObjectType> { [waterType, bodyMassType] }

    /// Stored rather than computed so `@Observable` actually invalidates views when it
    /// changes. A computed property reading `store` is invisible to observation tracking,
    /// which meant the UI kept showing a stale "Not connected" forever.
    private(set) var connectionState: HealthConnectionState = .unknown
    /// Whether we can write water samples. This is the one permission HealthKit will tell us
    /// about, because granting or denying a *write* leaks nothing about the person's data.
    private(set) var canWriteWater = false

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Determines whether the person has already answered our authorization request.
    ///
    /// HealthKit deliberately never reveals whether a *read* permission was granted — saying
    /// "denied" would itself disclose that someone is hiding data — so `authorizationStatus`
    /// reports only on write types and returns denied for everything else. Checking it alone
    /// meant someone who granted weight reading but not water writing looked disconnected
    /// even while the app was successfully reading their weight.
    ///
    /// `statusForAuthorizationRequest` answers the question we can actually answer: has this
    /// person been through the prompt for these types. That maps to what "connected" means to
    /// a user far better than any single permission does.
    func refreshConnectionState() async {
        guard isHealthDataAvailable else {
            connectionState = .unavailable
            return
        }
        let status = try? await store.statusForAuthorizationRequest(toShare: shareTypes, read: readTypes)
        connectionState = status == .unnecessary ? .connected : .notConnected
        canWriteWater = store.authorizationStatus(for: waterType) == .sharingAuthorized
    }

    func requestAuthorization() async {
        guard isHealthDataAvailable else {
            connectionState = .unavailable
            return
        }
        _ = try? await store.requestAuthorization(toShare: shareTypes, read: readTypes)
        await refreshConnectionState()
    }

    /// Writes a water intake sample to HealthKit and returns its sample UUID.
    @discardableResult
    func logWater(volumeML: Int, date: Date = .now) async throws -> UUID {
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(volumeML))
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)
        try await store.save(sample)
        return sample.uuid
    }

    /// Deletes a previously-written water sample by its HealthKit UUID.
    ///
    /// `HKHealthStore` has no "delete by ID" call — deleting requires the actual `HKObject`, so
    /// this looks the sample up by UUID first. Silently returns if it's already gone (deleted
    /// from the Health app directly, say) rather than treating a missing sample as an error:
    /// the end state either way is "this UUID isn't in HealthKit," which is what the caller
    /// wants.
    func deleteWaterSample(id: UUID) async throws {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: waterType, predicate: HKQuery.predicateForObject(with: id))],
            sortDescriptors: []
        )
        guard let sample = try await descriptor.result(for: store).first else { return }
        try await store.delete(sample)
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
            var hasResumed = false
            let query = HKUserAnnotatedMedicationQuery(predicate: nil, limit: HKObjectQueryNoLimit) { _, medication, done, error in
                guard !hasResumed else { return }
                if let error {
                    hasResumed = true
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
                    hasResumed = true
                    continuation.resume(returning: results)
                }
            }
            store.execute(query)
        }
    }
}
