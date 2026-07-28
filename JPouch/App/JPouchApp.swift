import SwiftUI
import SwiftData

@main
struct JPouchApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(PersistenceSetup.shared.container)
    }
}
