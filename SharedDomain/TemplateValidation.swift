import Foundation

struct TemplateIssue: Equatable, Sendable, Identifiable {
    enum Kind: String, Equatable, Sendable {
        case emptyName
        case noComponents
        case invalidIncrement
        case nonPositiveDuration
        case underallocated
        case overallocated
        case missingRoomExit
    }

    var kind: Kind
    var message: String
    var componentID: UUID?

    var id: String { "\(kind.rawValue)-\(componentID?.uuidString ?? "template")" }
}

struct TemplateValidation: Equatable, Sendable {
    var issues: [TemplateIssue]
    var allocatedSeconds: Int
    var plannedSeconds: Int

    var deltaSeconds: Int { allocatedSeconds - plannedSeconds }

    var unallocatedSeconds: Int { max(0, plannedSeconds - allocatedSeconds) }

    var excessSeconds: Int { max(0, allocatedSeconds - plannedSeconds) }

    var isBalanced: Bool { deltaSeconds == 0 }

    var blockingIssues: [TemplateIssue] {
        issues.filter { issue in
            switch issue.kind {
            case .emptyName, .noComponents, .invalidIncrement, .nonPositiveDuration, .underallocated, .overallocated:
                return true
            case .missingRoomExit:
                return false
            }
        }
    }

    var isLaunchable: Bool {
        blockingIssues.isEmpty && isBalanced
    }

    var allocationSummary: String {
        if isBalanced {
            return "Allocated time matches the \(DurationFormatting.short(plannedSeconds)) visit."
        }
        if deltaSeconds < 0 {
            return "\(DurationFormatting.short(unallocatedSeconds)) still unallocated. Adjust components or use Fit to total."
        }
        return "Components exceed the visit by \(DurationFormatting.short(excessSeconds)). Adjust components or use the component total."
    }

    static func validate(_ template: VisitTemplate) -> TemplateValidation {
        var issues: [TemplateIssue] = []
        if template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(TemplateIssue(kind: .emptyName, message: "Give this template a name.", componentID: nil))
        }
        if template.components.isEmpty {
            issues.append(TemplateIssue(kind: .noComponents, message: "Add at least one component.", componentID: nil))
        }
        for component in template.components {
            if component.durationSeconds <= 0 {
                issues.append(
                    TemplateIssue(
                        kind: .nonPositiveDuration,
                        message: "“\(component.title)” needs a duration.",
                        componentID: component.id
                    )
                )
            } else if !DurationMath.isValidIncrement(component.durationSeconds) {
                issues.append(
                    TemplateIssue(
                        kind: .invalidIncrement,
                        message: "“\(component.title)” must use 30-second increments.",
                        componentID: component.id
                    )
                )
            }
        }
        if !DurationMath.isValidIncrement(template.plannedDurationSeconds) {
            issues.append(
                TemplateIssue(
                    kind: .invalidIncrement,
                    message: "Total visit duration must use 30-second increments.",
                    componentID: nil
                )
            )
        }

        let allocated = template.allocatedSeconds
        if allocated < template.plannedDurationSeconds {
            issues.append(
                TemplateIssue(
                    kind: .underallocated,
                    message: "\(DurationFormatting.short(template.plannedDurationSeconds - allocated)) remains unallocated.",
                    componentID: nil
                )
            )
        } else if allocated > template.plannedDurationSeconds {
            issues.append(
                TemplateIssue(
                    kind: .overallocated,
                    message: "Components exceed the visit by \(DurationFormatting.short(allocated - template.plannedDurationSeconds)).",
                    componentID: nil
                )
            )
        }

        if let exitID = template.roomExitComponentID, !template.components.contains(where: { $0.id == exitID }) {
            issues.append(
                TemplateIssue(
                    kind: .missingRoomExit,
                    message: "The EXIT ROOM milestone is no longer in this template.",
                    componentID: exitID
                )
            )
        }

        return TemplateValidation(
            issues: issues,
            allocatedSeconds: allocated,
            plannedSeconds: template.plannedDurationSeconds
        )
    }
}
