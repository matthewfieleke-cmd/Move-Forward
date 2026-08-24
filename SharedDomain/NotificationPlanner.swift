import Foundation

struct PlannedAlert: Equatable, Sendable, Identifiable {
    var identifier: String
    var fireDate: Date
    var title: String
    var body: String
    var isCompletion: Bool
    var componentID: UUID?

    var id: String { identifier }
}

enum NotificationPlanner {
    static func componentIdentifier(sessionID: UUID, componentID: UUID) -> String {
        "mf.\(sessionID.uuidString).c.\(componentID.uuidString)"
    }

    static func completionIdentifier(sessionID: UUID) -> String {
        "mf.\(sessionID.uuidString).complete"
    }

    static func allIdentifiers(for sessionID: UUID, template: VisitTemplate) -> [String] {
        var identifiers = template.components.dropFirst().map {
            componentIdentifier(sessionID: sessionID, componentID: $0.id)
        }
        identifiers.append(completionIdentifier(sessionID: sessionID))
        return identifiers
    }

    static func prefix(for sessionID: UUID) -> String {
        "mf.\(sessionID.uuidString)."
    }

    static func futureAlerts(
        for session: VisitSession,
        now: Date,
        minimumLead: TimeInterval = 0.45
    ) -> [PlannedAlert] {
        guard session.state == .active else { return [] }
        let timeline = TemplateTimeline.build(from: session.templateSnapshot)
        var alerts: [PlannedAlert] = []

        for step in timeline.steps.dropFirst() {
            let fireDate = session.startedAt.addingTimeInterval(TimeInterval(step.startOffsetSeconds))
            guard fireDate.timeIntervalSince(now) > minimumLead else { continue }
            alerts.append(
                PlannedAlert(
                    identifier: componentIdentifier(sessionID: session.id, componentID: step.componentID),
                    fireDate: fireDate,
                    title: step.title,
                    body: session.templateSnapshot.name,
                    isCompletion: false,
                    componentID: step.componentID
                )
            )
        }

        let completionDate = session.plannedEndedAt
        if completionDate.timeIntervalSince(now) > minimumLead {
            alerts.append(
                PlannedAlert(
                    identifier: completionIdentifier(sessionID: session.id),
                    fireDate: completionDate,
                    title: session.templateSnapshot.completionMessage,
                    body: session.templateSnapshot.name,
                    isCompletion: true,
                    componentID: nil
                )
            )
        }
        return alerts
    }
}
