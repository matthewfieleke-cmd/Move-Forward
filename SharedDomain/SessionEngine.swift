import Foundation

protocol Clock: Sendable {
    func now() -> Date
}

struct SystemClock: Clock {
    func now() -> Date { Date() }
}

struct LiveProjection: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case idle
        case running
        case completed
        case ended
    }

    var phase: Phase
    var templateName: String
    var completionMessage: String
    var componentIndex: Int
    var componentCount: Int
    var componentTitle: String
    var componentRemaining: TimeInterval
    var visitRemaining: TimeInterval
    var elapsed: TimeInterval
    var visitProgress: Double
    var componentProgress: Double
    var isRoomExitComponent: Bool
    var isPostRoom: Bool
    var timeUntilRoomExit: TimeInterval?
    var roomExitTitle: String?
    var componentStartDate: Date
    var componentEndDate: Date
    var visitEndDate: Date
}

enum SessionEngine {
    static func start(
        template: VisitTemplate,
        at now: Date,
        origin: DeviceOrigin,
        sessionID: UUID = UUID()
    ) -> VisitSession {
        VisitSession(
            id: sessionID,
            templateSnapshot: template,
            startedAt: now,
            plannedEndedAt: now.addingTimeInterval(TimeInterval(template.plannedDurationSeconds)),
            state: .active,
            origin: origin,
            revision: 1,
            notificationIdentifiers: NotificationPlanner.allIdentifiers(for: sessionID, template: template),
            endedAt: nil
        )
    }

    static func endManually(_ session: VisitSession, at now: Date) -> VisitSession {
        var next = session
        next.state = .ended
        next.endedAt = now
        next.revision += 1
        return next
    }

    static func restart(
        replacing session: VisitSession,
        template: VisitTemplate,
        at now: Date,
        origin: DeviceOrigin
    ) -> (ended: VisitSession, started: VisitSession) {
        (endManually(session, at: now), start(template: template, at: now, origin: origin))
    }

    static func reconcile(
        session: VisitSession,
        now: Date,
        alreadyCountedSessionIDs: Set<UUID>
    ) -> (session: VisitSession, completion: CompletedVisit?) {
        guard session.state == .active else { return (session, nil) }
        guard now >= session.plannedEndedAt else { return (session, nil) }

        var completed = session
        completed.state = .completed
        completed.endedAt = session.plannedEndedAt
        completed.revision += 1

        if alreadyCountedSessionIDs.contains(session.id) {
            return (completed, nil)
        }

        let visit = CompletedVisit(
            sessionID: session.id,
            templateID: session.templateSnapshot.id,
            templateName: session.templateSnapshot.name,
            completedAt: session.plannedEndedAt,
            plannedDurationSeconds: session.plannedDurationSeconds
        )
        return (completed, visit)
    }

    static func projection(session: VisitSession, now: Date) -> LiveProjection {
        let timeline = TemplateTimeline.build(from: session.templateSnapshot)
        let elapsed = now.timeIntervalSince(session.startedAt)
        let planned = TimeInterval(session.plannedDurationSeconds)
        let visitRemaining = max(0, planned - elapsed)
        let visitEnd = session.plannedEndedAt

        if session.state == .ended {
            return terminalProjection(
                session: session,
                timeline: timeline,
                phase: .ended,
                elapsed: min(elapsed, planned),
                visitRemaining: visitRemaining,
                visitEnd: visitEnd,
                now: now
            )
        }

        if session.state == .completed || elapsed >= planned {
            let last = timeline.steps.last
            return LiveProjection(
                phase: .completed,
                templateName: session.templateName,
                completionMessage: session.templateSnapshot.completionMessage,
                componentIndex: last?.index ?? 0,
                componentCount: timeline.steps.count,
                componentTitle: session.templateSnapshot.completionMessage,
                componentRemaining: 0,
                visitRemaining: 0,
                elapsed: planned,
                visitProgress: 1,
                componentProgress: 1,
                isRoomExitComponent: false,
                isPostRoom: timeline.roomExitStep != nil,
                timeUntilRoomExit: nil,
                roomExitTitle: timeline.roomExitStep?.title,
                componentStartDate: visitEnd,
                componentEndDate: visitEnd,
                visitEndDate: visitEnd
            )
        }

        let step = timeline.step(atElapsed: elapsed) ?? timeline.steps[0]
        let componentStart = session.startedAt.addingTimeInterval(TimeInterval(step.startOffsetSeconds))
        let componentEnd = session.startedAt.addingTimeInterval(TimeInterval(step.endOffsetSeconds))
        let componentRemaining = max(0, componentEnd.timeIntervalSince(now))
        let componentElapsed = max(0, now.timeIntervalSince(componentStart))
        let exitStep = timeline.roomExitStep
        let isPostRoom: Bool
        let timeUntilExit: TimeInterval?
        if let exitStep {
            isPostRoom = elapsed >= TimeInterval(exitStep.startOffsetSeconds)
            timeUntilExit = isPostRoom ? nil : max(0, TimeInterval(exitStep.startOffsetSeconds) - elapsed)
        } else {
            isPostRoom = false
            timeUntilExit = nil
        }

        return LiveProjection(
            phase: .running,
            templateName: session.templateName,
            completionMessage: session.templateSnapshot.completionMessage,
            componentIndex: step.index,
            componentCount: timeline.steps.count,
            componentTitle: step.title,
            componentRemaining: componentRemaining,
            visitRemaining: visitRemaining,
            elapsed: max(0, elapsed),
            visitProgress: min(1, max(0, elapsed / max(planned, 0.001))),
            componentProgress: min(1, max(0, componentElapsed / max(TimeInterval(step.durationSeconds), 0.001))),
            isRoomExitComponent: step.isRoomExit,
            isPostRoom: isPostRoom && !step.isRoomExit,
            timeUntilRoomExit: timeUntilExit,
            roomExitTitle: exitStep?.title,
            componentStartDate: componentStart,
            componentEndDate: componentEnd,
            visitEndDate: visitEnd
        )
    }

    private static func terminalProjection(
        session: VisitSession,
        timeline: TemplateTimeline,
        phase: LiveProjection.Phase,
        elapsed: TimeInterval,
        visitRemaining: TimeInterval,
        visitEnd: Date,
        now: Date
    ) -> LiveProjection {
        let step = timeline.step(atElapsed: elapsed) ?? timeline.steps.first
        return LiveProjection(
            phase: phase,
            templateName: session.templateName,
            completionMessage: session.templateSnapshot.completionMessage,
            componentIndex: step?.index ?? 0,
            componentCount: timeline.steps.count,
            componentTitle: step?.title ?? session.templateName,
            componentRemaining: 0,
            visitRemaining: max(0, visitRemaining),
            elapsed: elapsed,
            visitProgress: min(1, elapsed / max(TimeInterval(session.plannedDurationSeconds), 0.001)),
            componentProgress: 0,
            isRoomExitComponent: step?.isRoomExit ?? false,
            isPostRoom: false,
            timeUntilRoomExit: nil,
            roomExitTitle: timeline.roomExitStep?.title,
            componentStartDate: now,
            componentEndDate: now,
            visitEndDate: visitEnd
        )
    }
}
