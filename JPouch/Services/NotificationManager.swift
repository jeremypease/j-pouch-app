import Foundation
import UserNotifications

/// Schedules local reminders for medication courses tracked directly in J-Pouch.
///
/// This is separate from the Health app's own medication reminders (iOS 26+) — those apply
/// only to medications added in Health, whereas courses logged here (e.g. antibiotics) are
/// J-Pouch-local so they need their own notifications regardless of iOS version.
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleReminders(for medication: MedicationEntry) async {
        await cancelReminders(for: medication)
        guard medication.reminderEnabled, !medication.reminderMinutesOfDay.isEmpty else { return }

        for minutes in medication.reminderMinutesOfDay {
            let content = UNMutableNotificationContent()
            content.title = "Medication reminder"
            content.body = medication.dosage.isEmpty
                ? "Time to take \(medication.name)."
                : "Time to take \(medication.name) (\(medication.dosage))."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = minutes / 60
            dateComponents.minute = minutes % 60

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: identifier(for: medication, minutes: minutes),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelReminders(for medication: MedicationEntry) async {
        let prefix = "medication-\(medication.id)-"
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func identifier(for medication: MedicationEntry, minutes: Int) -> String {
        "medication-\(medication.id)-\(minutes)"
    }
}
