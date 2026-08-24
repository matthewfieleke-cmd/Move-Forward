import Foundation
import UserNotifications

protocol NotificationScheduling: AnyObject {
    func requestAuthorization() async -> Bool
    func pendingIdentifiers() async -> [String]
    func add(alerts: [PlannedAlert]) async
    func remove(identifiers: [String])
    func removeDelivered(identifiers: [String])
    func authorizationStatus() async -> UNAuthorizationStatus
}

final class UserNotificationScheduler: NSObject, NotificationScheduling, UNUserNotificationCenterDelegate {
    var presentsInForeground = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
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
            content.sound = nil
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

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        presentsInForeground ? [] : [.banner, .list]
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

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationGranted ? .authorized : .denied
    }
}
