import Foundation

struct TimelineStep: Identifiable, Equatable, Sendable, Hashable {
    var componentID: UUID
    var index: Int
    var title: String
    var durationSeconds: Int
    var startOffsetSeconds: Int
    var endOffsetSeconds: Int
    var isRoomExit: Bool

    var id: UUID { componentID }
}

struct TemplateTimeline: Equatable, Sendable {
    var steps: [TimelineStep]
    var plannedDurationSeconds: Int

    var allocatedSeconds: Int {
        steps.reduce(0) { $0 + $1.durationSeconds }
    }

    var roomExitStep: TimelineStep? {
        steps.first(where: \.isRoomExit)
    }

    static func build(from template: VisitTemplate) -> TemplateTimeline {
        var offset = 0
        var steps: [TimelineStep] = []
        for (index, component) in template.components.enumerated() {
            let end = offset + component.durationSeconds
            steps.append(
                TimelineStep(
                    componentID: component.id,
                    index: index,
                    title: component.title,
                    durationSeconds: component.durationSeconds,
                    startOffsetSeconds: offset,
                    endOffsetSeconds: end,
                    isRoomExit: component.id == template.roomExitComponentID
                )
            )
            offset = end
        }
        return TemplateTimeline(steps: steps, plannedDurationSeconds: template.plannedDurationSeconds)
    }

    func step(atElapsed elapsed: TimeInterval) -> TimelineStep? {
        guard !steps.isEmpty else { return nil }
        if elapsed < 0 { return steps[0] }
        for step in steps {
            if elapsed < TimeInterval(step.endOffsetSeconds) {
                return step
            }
        }
        return steps.last
    }

    func boundaryOffsetsSeconds() -> [Int] {
        var offsets = steps.map(\.startOffsetSeconds)
        offsets.append(plannedDurationSeconds)
        return offsets
    }
}
