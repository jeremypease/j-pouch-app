import SwiftUI
import SwiftData

struct TrendsView: View {
    @Query(sort: \OutputEntry.timestamp, order: .reverse) private var outputEntries: [OutputEntry]
    @Query(sort: \HydrationEntry.timestamp, order: .reverse) private var hydrationEntries: [HydrationEntry]

    var body: some View {
        NavigationStack {
            List {
                Section("Recent Output") {
                    if outputEntries.isEmpty {
                        Text("No entries yet.").foregroundStyle(.secondary)
                    }
                    ForEach(outputEntries.prefix(10)) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.timestamp, style: .date) + Text(" \u{2022} ") + Text(entry.timestamp, style: .time)
                            Text("Consistency \(entry.consistency)/7 \u{2022} Pain \(entry.pain)/5\(entry.blood != .none ? " \u{2022} Blood: \(entry.blood.displayName)" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Recent Hydration") {
                    if hydrationEntries.isEmpty {
                        Text("No entries yet.").foregroundStyle(.secondary)
                    }
                    ForEach(hydrationEntries.prefix(10)) { entry in
                        Text("\(entry.volumeML) mL \u{2022} \(entry.kind.displayName)")
                    }
                }
                Section {
                    Button("Generate GI Visit Report") {}
                        .disabled(true)
                }
            }
            .navigationTitle("Trends")
        }
    }
}
