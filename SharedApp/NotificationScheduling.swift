import Foundation
import UserNotifications

protocol NotificationScheduling: AnyObject {
    func requestAuthorization() async -> Bool
    func pendingIdentifiers() async -> [String]
    func add(alerts: [PlannedAlert]) async
    func remove(identifiers: [String])
    func removeDelivered(identifiers: [String])
    func removeDelivered(matchingPrefix prefix: String) async
    func authorizationStatus() async -> UNAuthorizationStatus
}

final class UserNotificationScheduler: NSObject, NotificationScheduling, UNUserNotificationCenterDelegate {
    /// The app plays its own haptic and updates the UI while it is on screen, so the
    /// duplicate system banner is suppressed only in that case.
    var suppressesForegroundAlerts = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func pendingIdentifiers() async -> [String] {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.map(\.identifier)
    }

    func add(alerts: [PlannedAlert]) async {
        for alert in alerts {
            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.body
            // Apple Watch pairs its notification haptic with the standard alert sound.
            // Silent Mode keeps the wrist tap without audio.
            content.sound = .default
            content.interruptionLevel = .active
            content.threadIdentifier = "move-forward-visit"
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alert.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: alert.identifier, content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    func remove(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeDelivered(identifiers: [String]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removeDelivered(matchingPrefix prefix: String) async {
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        let identifiers = delivered.map(\.request.identifier).filter { $0.hasPrefix(prefix) }
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        suppressesForegroundAlerts ? [] : [.banner, .list, .sound]
    }
}

final class MockNotificationScheduler: NotificationScheduling {
    var authorizationGranted = true
    var pending: [PlannedAlert] = []
    var delivered: [String] = []

    func requestAuthorization() async -> Bool { authorizationGranted }

    func pendingIdentifiers() async -> [String] { pending.map(\.identifier) }

    func add(alerts: [PlannedAlert]) async {
        pending.removeAll { existing in alerts.contains(where: { $0.identifier == existing.identifier }) }
        pending.append(contentsOf: alerts)
    }

    func remove(identifiers: [String]) {
        pending.removeAll { identifiers.contains($0.identifier) }
    }

    func removeDelivered(identifiers: [String]) {
        delivered.removeAll { identifiers.contains($0) }
    }

    func removeDelivered(matchingPrefix prefix: String) async {
        delivered.removeAll { $0.hasPrefix(prefix) }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationGranted ? .authorized : .denied
    }
}
