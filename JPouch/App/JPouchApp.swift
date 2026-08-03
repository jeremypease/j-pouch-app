import SwiftUI
import SwiftData

@main
struct JPouchApp: App {
    init() {
        #if DEBUG
        // A missing or misnamed bundled font falls back to the system face silently, which
        // reads as "the design didn't apply" and is tedious to trace. Say so at launch instead.
        JP.Font.verifyRegistration()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(PersistenceSetup.shared.container)
    }
}
