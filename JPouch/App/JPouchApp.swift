import SwiftUI
import SwiftData

@main
struct JPouchApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            OutputEntry.self,
            HydrationEntry.self,
            FoodEntry.self,
            MedicationEntry.self,
        ])
        let configuration = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
