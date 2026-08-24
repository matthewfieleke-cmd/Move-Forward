import Foundation

@MainActor
final class SessionNotificationController {
    var scheduler: NotificationScheduling
    var schedulesSystemNotifications: Bool
    private(set) var lastScheduledIdentifiers: [UUID: [String]] = [:]

    init(scheduler: NotificationScheduling, schedulesSystemNotifications: Bool) {
        self.scheduler = scheduler
        self.schedulesSystemNotifications = schedulesSystemNotifications
    }

    func cancel(sessionID: UUID, knownIdentifiers: [String] = []) async {
        var identifiers = Set(knownIdentifiers)
        identifiers.formUnion(lastScheduledIdentifiers[sessionID] ?? [])
        identifiers.insert(NotificationPlanner.completionIdentifier(sessionID: sessionID))
        let list = Array(identifiers)
        scheduler.remove(identifiers: list)
        scheduler.removeDelivered(identifiers: list)
        lastScheduledIdentifiers[sessionID] = []
    }

    /// Clears alerts this app already delivered, including ones left by sessions this
    /// launch knows nothing about, so Notification Center never accumulates a day of them.
    func sweepDeliveredAlerts() async {
        await scheduler.removeDelivered(matchingPrefix: NotificationPlanner.identifierPrefix)
    }

    func reschedule(session: VisitSession, now: Date) async -> [PlannedAlert] {
        await cancel(sessionID: session.id, knownIdentifiers: session.notificationIdentifiers)
        let alerts = NotificationPlanner.futureAlerts(for: session, now: now)
        lastScheduledIdentifiers[session.id] = alerts.map(\.identifier)
        guard schedulesSystemNotifications else { return alerts }
        await scheduler.add(alerts: alerts)
        return alerts
    }
}
