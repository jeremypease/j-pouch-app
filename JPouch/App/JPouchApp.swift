import SwiftUI
import SwiftData

@main
struct JPouchApp: App {
    init() {
        JPouchAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(PersistenceSetup.shared.container)
    }
}
