import SwiftUI

/// Picks how often one kind of reminder fires, with presets plus a custom list of times.
///
/// Shared between onboarding and Settings so the two can't drift into describing the same
/// setting differently.
struct ReminderCadenceCard: View {
    let kind: ReminderKind
    @Binding var cadence: ReminderCadence
    @Binding var minutes: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.md) {
            JPCardHeader(title: kind.title, icon: kind == .hydration ? "drop.fill" : "square.and.pencil")
            JPCaption(kind.explanation)

            JPTagPicker(
                options: ReminderCadence.presets + [.custom],
                title: { $0.displayName(for: kind) },
                tint: JP.Color.accent,
                selection: Binding(
                    get: { cadence },
                    set: { newValue in
                        cadence = newValue
                        // Seed custom with the previous preset's times so it starts from
                        // something sensible instead of an empty list with nothing to edit.
                        if newValue == .custom {
                            if minutes.isEmpty { minutes = ReminderCadence.default(for: kind).times(for: kind) }
                        } else {
                            minutes = newValue.times(for: kind)
                        }
                    }
                )
            )

            if cadence == .custom {
                customTimes
            } else if minutes.isEmpty {
                JPCaption("No reminders for this.")
            } else {
                JPCaption("At \(minutes.sorted().map(\.asTimeOfDay).formatted(.list(type: .and))).")
            }
        }
        .jpCard()
    }

    private var customTimes: some View {
        VStack(alignment: .leading, spacing: JP.Spacing.sm) {
            ForEach(Array(minutes.sorted().enumerated()), id: \.offset) { index, minute in
                HStack {
                    DatePicker(
                        "Reminder \(index + 1)",
                        selection: Binding(
                            get: { Self.date(fromMinutes: minute) },
                            set: { newDate in
                                var updated = minutes.sorted()
                                updated[index] = Self.minutes(from: newDate)
                                minutes = updated.sorted()
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()

                    Spacer(minLength: 0)

                    Button {
                        var updated = minutes.sorted()
                        updated.remove(at: index)
                        minutes = updated
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(JP.Color.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove reminder at \(minute.asTimeOfDay)")
                }
            }

            Button("Add a time") {
                // Somewhere in the middle of the day rather than midnight, which is never what
                // anyone wants and takes a lot of spinning to correct.
                let candidate = minutes.contains(12 * 60) ? (15 * 60) : (12 * 60)
                minutes = (minutes + [candidate]).sorted()
            }
            .buttonStyle(.jpSecondary)

            if minutes.isEmpty {
                JPCaption("No times set, so nothing will fire.")
            }
        }
    }

    private static func date(fromMinutes minute: Int) -> Date {
        var components = DateComponents()
        components.hour = minute / 60
        components.minute = minute % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
