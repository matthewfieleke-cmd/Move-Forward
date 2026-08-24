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
    /// Every alert this app schedules carries this prefix so stale ones can be swept
    /// even when the session that created them is long gone.
    static let identifierPrefix = "mf."

    /// The room-exit checkpoint fires twice so it is unmistakable on the wrist without
    /// looking at the watch. One second is the closest two calendar triggers can sit,
    /// since they only resolve to whole seconds.
    static let roomExitRepeatDelay: TimeInterval = 1

    static func componentIdentifier(sessionID: UUID, componentID: UUID, repeatIndex: Int = 0) -> String {
        let base = "\(identifierPrefix)\(sessionID.uuidString).c.\(componentID.uuidString)"
        return repeatIndex == 0 ? base : "\(base).r\(repeatIndex)"
    }

    static func completionIdentifier(sessionID: UUID) -> String {
        "\(identifierPrefix)\(sessionID.uuidString).complete"
    }

    static func allIdentifiers(for sessionID: UUID, template: VisitTemplate) -> [String] {
        var identifiers: [String] = []
        for component in template.components.dropFirst() {
            identifiers.append(componentIdentifier(sessionID: sessionID, componentID: component.id))
            if component.id == template.roomExitComponentID {
                identifiers.append(
                    componentIdentifier(sessionID: sessionID, componentID: component.id, repeatIndex: 1)
                )
            }
        }
        identifiers.append(completionIdentifier(sessionID: sessionID))
        return identifiers
    }

    static func prefix(for sessionID: UUID) -> String {
        "\(identifierPrefix)\(sessionID.uuidString)."
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
            guard step.isRoomExit else { continue }
            alerts.append(
                PlannedAlert(
                    identifier: componentIdentifier(
                        sessionID: session.id,
                        componentID: step.componentID,
                        repeatIndex: 1
                    ),
                    fireDate: fireDate.addingTimeInterval(roomExitRepeatDelay),
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
