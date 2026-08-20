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

    /// Shared with the JPouchWidget extension, which needs to open the same store — a widget
    /// process can't reach the app's private container. Must match the App Group entitlement
    /// on both targets (`project.yml`) and be enabled on the App ID in the Apple Developer
    /// portal, or `appGroupStoreURL` resolves to nil and the app falls back to its private,
    /// non-shared container (the widget just won't see data in that case).
    private static let appGroupIdentifier = "group.com.jeremypease.jpouch"
    private static let storeFileName = "JPouch.sqlite"

    /// Where the store lived before the widget shipped: SwiftData's default location when no
    /// `url:` is passed to `ModelConfiguration` is `<Application Support>/default.store`.
    private static var legacyStoreURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("default.store")
    }

    private static var appGroupStoreURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(storeFileName)
    }

    /// One-time move from the app's private container into the shared App Group container, so
    /// the app and the widget extension can open the same store. Existing installs already have
    /// data at the pre-widget location — without this, that data doesn't get deleted, but it
    /// does become invisible: `make()` opens whatever is at `appGroupStoreURL` instead, which is
    /// empty on an existing install's first launch after the update.
    ///
    /// Deliberately conservative: copies rather than moves the store file (and its SQLite
    /// `-wal`/`-shm` siblings, if present), and only when the new location doesn't already have
    /// a store — so a second launch, or one that races with CloudKit already having synced
    /// content into the new location, never overwrites anything. The old files are left in place
    /// rather than deleted: the disk cost is a few MB at most, and there's no safe way to undo a
    /// wrong deletion. This has not been exercised against a real CloudKit-synced install and
    /// should be tested against one — a real device with existing logged data — before shipping.
    private static func migrateLegacyStoreIfNeeded() {
        guard let legacyStoreURL, let appGroupStoreURL else { return }
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyStoreURL.path) else { return }
        guard !fm.fileExists(atPath: appGroupStoreURL.path) else { return }

        do {
            try fm.createDirectory(
                at: appGroupStoreURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            for suffix in ["", "-wal", "-shm"] {
                let source = URL(fileURLWithPath: legacyStoreURL.path + suffix)
                guard fm.fileExists(atPath: source.path) else { continue }
                let destination = URL(fileURLWithPath: appGroupStoreURL.path + suffix)
                try fm.copyItem(at: source, to: destination)
            }
        } catch {
            // Best-effort: if the copy fails partway, fall through and let ModelContainer open
            // (or create) a store at the App Group location on its own. The legacy files are
            // untouched either way, so nothing already on disk is lost — just not yet migrated.
        }
    }

    private static func makeConfiguration(cloudKitDatabase: ModelConfiguration.CloudKitDatabase) -> ModelConfiguration {
        guard let appGroupStoreURL else {
            return ModelConfiguration(schema: schema, cloudKitDatabase: cloudKitDatabase)
        }
        return ModelConfiguration(schema: schema, url: appGroupStoreURL, cloudKitDatabase: cloudKitDatabase)
    }

    private static func make() -> PersistenceSetup {
        migrateLegacyStoreIfNeeded()

        let attempts: [(StorageMode, ModelConfiguration)] = [
            (.cloudKit, makeConfiguration(cloudKitDatabase: .automatic)),
            (.localOnly, makeConfiguration(cloudKitDatabase: .none)),
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
