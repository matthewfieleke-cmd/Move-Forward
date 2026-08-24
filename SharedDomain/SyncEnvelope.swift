import Foundation

enum SyncMessageKind: String, Codable, Sendable {
    case fullState
    case templates
    case sessionStart
    case sessionEnd
    case sessionRestart
    case sessionComplete
    case testAlert
    case ack
}

struct SyncEnvelope: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var kind: SyncMessageKind
    var sentAt: Date
    var origin: DeviceOrigin
    var messageID: UUID
    var templates: [VisitTemplate]?
    var templatesRevision: Int?
    var session: VisitSession?
    var completedVisits: [CompletedVisit]?
    var ackSessionID: UUID?
    var ackScheduledCount: Int?

    static func make(
        kind: SyncMessageKind,
        origin: DeviceOrigin,
        at sentAt: Date,
        templates: [VisitTemplate]? = nil,
        templatesRevision: Int? = nil,
        session: VisitSession? = nil,
        completedVisits: [CompletedVisit]? = nil,
        ackSessionID: UUID? = nil,
        ackScheduledCount: Int? = nil
    ) -> SyncEnvelope {
        SyncEnvelope(
            schemaVersion: 1,
            kind: kind,
            sentAt: sentAt,
            origin: origin,
            messageID: UUID(),
            templates: templates,
            templatesRevision: templatesRevision,
            session: session,
            completedVisits: completedVisits,
            ackSessionID: ackSessionID,
            ackScheduledCount: ackScheduledCount
        )
    }
}

struct SyncMergeResult: Equatable, Sendable {
    var snapshot: PersistedSnapshot
    var didChange: Bool
    var shouldReschedule: Bool
    var endedSessionIDs: [UUID]
}

enum SyncMerger {
    static func merge(
        local: PersistedSnapshot,
        incoming: SyncEnvelope,
        localDevice: DeviceOrigin
    ) -> SyncMergeResult {
        var snapshot = local
        var didChange = false
        var shouldReschedule = false
        var endedSessionIDs: [UUID] = []

        if incoming.kind == .ack {
            if incoming.origin != localDevice {
                snapshot.settings.lastWatchAckAt = incoming.sentAt
                snapshot.settings.lastWatchAckSessionID = incoming.ackSessionID
                snapshot.settings.lastWatchScheduledCount = incoming.ackScheduledCount
                didChange = true
            }
            return SyncMergeResult(snapshot: snapshot, didChange: didChange, shouldReschedule: false, endedSessionIDs: [])
        }

        if let templates = incoming.templates, let revision = incoming.templatesRevision {
            let shouldApply: Bool
            switch (localDevice, incoming.origin) {
            case (.watch, .phone):
                shouldApply = revision >= snapshot.templatesRevision
            case (.phone, .watch):
                shouldApply = snapshot.templates.isEmpty && !templates.isEmpty
            case (.phone, .phone), (.watch, .watch):
                shouldApply = revision > snapshot.templatesRevision
            }
            if shouldApply {
                snapshot.templates = templates.sorted { $0.sortOrder < $1.sortOrder }
                snapshot.templatesRevision = revision
                didChange = true
            }
        }

        if let incomingVisits = incoming.completedVisits {
            var existing = Set(snapshot.completedVisits.map(\.sessionID))
            for visit in incomingVisits where !existing.contains(visit.sessionID) {
                snapshot.completedVisits.append(visit)
                existing.insert(visit.sessionID)
                didChange = true
            }
        }

        if let incomingSession = incoming.session {
            let result = mergeSession(local: snapshot.session, incoming: incomingSession, kind: incoming.kind)
            if result.replaced, let previous = snapshot.session, previous.id != incomingSession.id, previous.state == .active {
                endedSessionIDs.append(previous.id)
            }
            if result.replaced {
                snapshot.session = result.session
                didChange = true
                shouldReschedule = result.session?.state == .active
            }
            if incomingSession.state == .completed {
                let completion = CompletedVisit(
                    sessionID: incomingSession.id,
                    templateID: incomingSession.templateSnapshot.id,
                    templateName: incomingSession.templateSnapshot.name,
                    completedAt: incomingSession.endedAt ?? incomingSession.plannedEndedAt,
                    plannedDurationSeconds: incomingSession.plannedDurationSeconds
                )
                if !snapshot.completedVisits.contains(where: { $0.sessionID == completion.sessionID }) {
                    snapshot.completedVisits.append(completion)
                    didChange = true
                }
            }
        } else if incoming.kind == .sessionEnd || incoming.kind == .sessionComplete {
            if var session = snapshot.session, session.state == .active {
                session.state = incoming.kind == .sessionEnd ? .ended : .completed
                session.endedAt = incoming.sentAt
                snapshot.session = session
                endedSessionIDs.append(session.id)
                didChange = true
            }
        }

        return SyncMergeResult(
            snapshot: snapshot,
            didChange: didChange,
            shouldReschedule: shouldReschedule,
            endedSessionIDs: endedSessionIDs
        )
    }

    private static func mergeSession(
        local: VisitSession?,
        incoming: VisitSession,
        kind: SyncMessageKind
    ) -> (session: VisitSession?, replaced: Bool) {
        guard let local else { return (incoming, true) }
        if local.id == incoming.id {
            if incoming.revision >= local.revision {
                return (incoming, incoming != local)
            }
            return (local, false)
        }
        if incoming.startedAt >= local.startedAt {
            return (incoming, true)
        }
        if kind == .sessionStart || kind == .sessionRestart {
            return (incoming, true)
        }
        return (local, false)
    }
}

enum WatchLinkStatus: Equatable, Sendable {
    case unknown
    case unsupported
    case unpaired
    case appNotInstalled
    case unreachable
    case reachable
    case pendingAck
    case synced

    var title: String {
        switch self {
        case .unknown: return "Checking Apple Watch"
        case .unsupported: return "Apple Watch not available here"
        case .unpaired: return "No Apple Watch paired"
        case .appNotInstalled: return "Not installed on Apple Watch"
        case .unreachable: return "Ready · watch asleep"
        case .reachable: return "Ready · connected"
        case .pendingAck: return "Ready · waiting for watch"
        case .synced: return "Ready · in sync"
        }
    }

    var detail: String {
        switch self {
        case .unknown:
            return "Move Forward is checking the paired Apple Watch."
        case .unsupported:
            return "This device cannot connect to Apple Watch."
        case .unpaired:
            return "Pair an Apple Watch in the Watch app to receive wrist cues."
        case .appNotInstalled:
            return "Open the Watch app on iPhone and install Move Forward."
        case .unreachable:
            return "Apple Watch drops the live link whenever its screen sleeps. That is normal. Templates, visits, and completed counts sync as soon as it wakes."
        case .reachable:
            return "Your watch is awake and receiving updates immediately."
        case .synced:
            return "Your watch has the current templates and visit."
        case .pendingAck:
            return "The visit started on iPhone. Your watch schedules its own alerts as soon as it wakes."
        }
    }

    /// Paired with the watch app installed, so syncing will happen. A sleeping watch
    /// still counts as ready because queued updates arrive when it wakes.
    var isReady: Bool {
        switch self {
        case .unreachable, .reachable, .pendingAck, .synced:
            return true
        case .unknown, .unsupported, .unpaired, .appNotInstalled:
            return false
        }
    }
}
