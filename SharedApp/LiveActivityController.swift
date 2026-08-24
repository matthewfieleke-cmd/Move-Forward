import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class LiveActivityController {
    func start(session: VisitSession, now: Date) {
        #if canImport(ActivityKit) && os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let projection = SessionEngine.projection(session: session, now: now)
        let attributes = VisitActivityAttributes(templateName: session.templateName, sessionID: session.id)
        let state = state(from: projection)
        let content = ActivityContent(state: state, staleDate: session.plannedEndedAt)
        _ = try? Activity<VisitActivityAttributes>.request(attributes: attributes, content: content)
        #endif
    }

    func update(session: VisitSession, now: Date) {
        #if canImport(ActivityKit) && os(iOS)
        let projection = SessionEngine.projection(session: session, now: now)
        let state = state(from: projection)
        let content = ActivityContent(state: state, staleDate: session.plannedEndedAt)
        Task {
            for activity in Activity<VisitActivityAttributes>.activities where activity.attributes.sessionID == session.id {
                await activity.update(content)
            }
        }
        #endif
    }

    func end(sessionID: UUID) {
        #if canImport(ActivityKit) && os(iOS)
        Task {
            for activity in Activity<VisitActivityAttributes>.activities where activity.attributes.sessionID == sessionID {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        #endif
    }

    #if canImport(ActivityKit) && os(iOS)
    private func state(from projection: LiveProjection) -> VisitActivityAttributes.ContentState {
        VisitActivityAttributes.ContentState(
            componentTitle: projection.componentTitle,
            componentIndex: projection.componentIndex,
            componentCount: projection.componentCount,
            componentStartDate: projection.componentStartDate,
            componentEndDate: projection.componentEndDate,
            visitEndDate: projection.visitEndDate,
            isRoomExit: projection.isRoomExitComponent,
            isPostRoom: projection.isPostRoom,
            phaseRaw: String(describing: projection.phase)
        )
    }
    #endif
}
