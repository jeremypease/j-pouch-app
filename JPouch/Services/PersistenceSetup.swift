import Foundation
import SwiftData

/// How the store ended up being created.
enum StorageMode: Equatable {
    /// Normal: synced to iCloud, so data survives losing or replacing the phone.
    case cloudKit
    /// The store opened, but without sync. Data is safe on this device and nowhere else.
    case localOnly
    /// Nothing on disk would open. The app runs, but nothing logged will survive relaunch.
    case inMemory

    var isSyncing: Bool { self == .cloudKit }
}

/// Builds the SwiftData container, degrading rather than refusing to launch.
///
/// This used to be `try!`. Any problem opening the store — a CloudKit entitlement mismatch, a
/// migration that can't be applied, a corrupt file — meant every user's app crashed on launch
/// with nothing they could do about it. Failing to sync is bad; failing to open at all is
/// worse, and for someone tracking symptoms it can mean losing access to their history exactly
/// when they need it.
struct PersistenceSetup {
    static let shared = make()

    let container: ModelContainer
    let mode: StorageMode

    private static let schema = Schema([
        UserProfile.self,
        OutputEntry.self,
        HydrationEntry.self,
        FoodEntry.self,
        MedicationEntry.self,
        SymptomEntry.self,
    ])

    private static func make() -> PersistenceSetup {
        let attempts: [(StorageMode, ModelConfiguration)] = [
            (.cloudKit, ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)),
            (.localOnly, ModelConfiguration(schema: schema, cloudKitDatabase: .none)),
            (.inMemory, ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)),
        ]

        for (mode, configuration) in attempts {
            if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
                return PersistenceSetup(container: container, mode: mode)
            }
        }

        // Every configuration failed, including in-memory — which needs no disk and no
        // entitlement, so it effectively cannot happen. There is nothing left to fall back to,
        // and continuing without a container is not possible, so trapping here is honest
        // rather than pretending to recover.
        fatalError("Could not create any model container, including in-memory.")
    }
}
