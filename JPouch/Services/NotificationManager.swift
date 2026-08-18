import Foundation
import UserNotifications

/// What reminders a medication should currently have scheduled.
///
/// Kept as a plain value so the decision — which is the part that was wrong — can be tested
/// without touching UNUserNotificationCenter.
enum ReminderPlan: Equatable {
    /// Nothing to schedule: reminders are off, no times set, or the course has finished.
    case none
    /// Open-ended course: repeat daily at these minutes-past-midnight, forever.
    case repeatingDaily(minutes: [Int])
    /// Course with an end date: individual dated reminders that expire on their own, so they
    /// stop even if the app is never reopened.
    case dated([DateComponents])
}

/// Everything the scheduler needs about one medication, as plain values.
///
/// Taken on the main actor so a SwiftData model never crosses into the scheduler's async work —
/// `ModelContext` isn't thread-safe, and reading a model's properties from a background task is
/// a race even when it appears to work.
struct MedicationReminder: Sendable, Equatable {
    var id: UUID
    var name: String
    var dosage: String
    var plan: ReminderPlan
}

extension MedicationEntry {
    @MainActor
    func reminderSnapshot(asOf referenceDate: Date = .now, calendar: Calendar = .current) -> MedicationReminder {
        MedicationReminder(
            id: id,
            name: name,
            dosage: dosage,
            plan: NotificationManager.plan(for: self, asOf: referenceDate, calendar: calendar)
        )
    }
}

/// Schedules local reminders for medication courses tracked directly in J-Pouch.
///
/// Separate from the Health app's own medication reminders (iOS 26+), which only cover
/// medications added in Health. Courses logged here — antibiotics especially — need their own.
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    /// iOS keeps at most 64 pending notifications per app. Staying well under it leaves room
    /// for other medications; a course longer than this falls back to a repeating reminder.
    static let maxDatedNotifications = 48

    // MARK: - Planning

    static func plan(
        for medication: MedicationEntry,
        asOf referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> ReminderPlan {
        let minutes = medication.reminderMinutesOfDay.sorted()
        guard medication.reminderEnabled, !minutes.isEmpty else { return .none }

        let today = calendar.startOfDay(for: referenceDate)

        guard let endDate = medication.endDate else {
            return .repeatingDaily(minutes: minutes)
        }

        let lastDay = calendar.startOfDay(for: endDate)
        // A finished course must not keep reminding. This was the bug: a 10-day antibiotic
        // course scheduled a repeating trigger and went on firing indefinitely.
        guard lastDay >= today else { return .none }

        let startDay = max(today, calendar.startOfDay(for: medication.startDate))
        let dayCount = (calendar.dateComponents([.day], from: startDay, to: lastDay).day ?? 0) + 1
        guard dayCount > 0 else { return .none }

        if dayCount * minutes.count > maxDatedNotifications {
            return .repeatingDaily(minutes: minutes)
        }

        var components: [DateComponents] = []
        for dayOffset in 0..<dayCount {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startDay) else { continue }
            for minute in minutes {
                guard let fireDate = calendar.date(
                    bySettingHour: minute / 60,
                    minute: minute % 60,
                    second: 0,
                    of: day
                ), fireDate > referenceDate else { continue }
                components.append(
                    calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                )
            }
        }
        return components.isEmpty ? .none : .dated(components)
    }

    // MARK: - Scheduling

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(_ reminder: MedicationReminder) async {
        await cancelReminders(forMedicationID: reminder.id)

        let identifierPrefix = Self.identifierPrefix(for: reminder.id)
        let content = Self.content(for: reminder)

        switch reminder.plan {
        case .none:
            return
        case .repeatingDaily(let minutes):
            for minute in minutes {
                var components = DateComponents()
                components.hour = minute / 60
                components.minute = minute % 60
                await add(
                    identifier: "\(identifierPrefix)daily-\(minute)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                )
            }
        case .dated(let componentsList):
            for (index, components) in componentsList.enumerated() {
                await add(
                    identifier: "\(identifierPrefix)dated-\(index)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
            }
        }
    }

    /// Re-derives every medication's reminders. Called at launch so courses that ended while
    /// the app was closed stop reminding, and so a device restored from iCloud — which syncs
    /// the medications but not the other device's scheduled notifications — gets its own.
    func sync(_ reminders: [MedicationReminder]) async {
        for reminder in reminders {
            await schedule(reminder)
        }
    }

    // MARK: - Daily hydration and logging reminders

    /// Replaces the daily reminders wholesale. Cancelling first means removing a time actually
    /// removes it, rather than leaving an orphan firing forever with nothing in the app that
    /// still refers to it.
    func syncDailyReminders(_ schedules: [DailyReminderSchedule]) async {
        await cancelDailyReminders()

        for schedule in schedules {
            let content = Self.content(for: schedule.kind)
            for minute in schedule.minutes.sorted() {
                var components = DateComponents()
                components.hour = minute / 60
                components.minute = minute % 60
                await add(
                    identifier: "\(Self.dailyPrefix)\(schedule.kind.rawValue)-\(minute)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                )
            }
        }
    }

    func cancelDailyReminders() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.dailyPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Whether notifications are actually permitted. Reminders configured while permission is
    /// denied silently never fire, so the UI needs to be able to say so rather than implying
    /// something is set up when nothing will happen.
    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    /// Whether iOS will still show a permission prompt. Once someone has denied, it won't ask
    /// again — the only route back is the Settings app, which the UI has to say out loud.
    func canStillAsk() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .notDetermined
    }

    /// Returns whether permission ended up granted, so a caller can react rather than assume.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }

    func cancelReminders(forMedicationID id: UUID) async {
        let prefix = Self.identifierPrefix(for: id)
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func add(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger) async {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private static let dailyPrefix = "daily-"

    private static func identifierPrefix(for id: UUID) -> String {
        "medication-\(id)-"
    }

    private static func content(for kind: ReminderKind) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        // Deliberately plain and low-pressure. These arrive several times a day, every day, to
        // someone already managing a chronic condition — anything that reads as scolding gets
        // the whole category switched off, and then the app learns nothing.
        switch kind {
        case .hydration:
            content.title = "Time for a drink"
            content.body = "Logging it keeps your hydration trend accurate."
        case .logging:
            content.title = "Anything to log?"
            content.body = "A quick entry now means your trends reflect the real day."
        }
        content.sound = .default
        return content
    }

    private static func content(for reminder: MedicationReminder) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Medication reminder"
        content.body = reminder.dosage.isEmpty
            ? "Time to take \(reminder.name)."
            : "Time to take \(reminder.name) (\(reminder.dosage))."
        content.sound = .default
        return content
    }
}
