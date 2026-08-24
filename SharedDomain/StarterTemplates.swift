import Foundation

enum StarterIDs {
    static func uuid(_ value: String) -> UUID {
        guard let parsed = UUID(uuidString: value) else {
            preconditionFailure("Invalid starter UUID \(value)")
        }
        return parsed
    }

    static let moveForward = uuid("A1111111-1111-4111-8111-111111111111")
    static let acuteVisit = uuid("A2222222-2222-4222-8222-222222222222")
    static let adultPhysical = uuid("A3333333-3333-4333-8333-333333333333")
    static let wellChild = uuid("A4444444-4444-4444-8444-444444444444")
}

enum StarterTemplates {
    static let all: [VisitTemplate] = [
        moveForward,
        acuteVisit,
        adultPhysical,
        wellChild
    ]

    static var moveForward: VisitTemplate {
        let components = [
            component("A1111111-1111-4111-8111-111111111101", "Greet and Smile!", minutes: 1),
            component("A1111111-1111-4111-8111-111111111102", "Understand their concerns, open-ended questions", minutes: 4),
            component("A1111111-1111-4111-8111-111111111103", "Examine relevant body areas", minutes: 2),
            component("A1111111-1111-4111-8111-111111111104", "Provide diagnosis and treatment plan", minutes: 4),
            component("A1111111-1111-4111-8111-111111111105", "EXIT room, place orders for medications/imaging/labs, and print off labs", minutes: 2),
            component("A1111111-1111-4111-8111-111111111106", "Tickler", minutes: 1),
            component("A1111111-1111-4111-8111-111111111107", "Nurse walk to lab or to front", minutes: 1),
            component("A1111111-1111-4111-8111-111111111108", "Finish note and on to next!", minutes: 5)
        ]
        return VisitTemplate(
            id: StarterIDs.moveForward,
            name: "Move Forward",
            plannedDurationSeconds: 20 * 60,
            components: components,
            completionMessage: "Dunzo! Good job!",
            roomExitComponentID: components[4].id,
            isFavorite: true,
            icon: .sparkle,
            accent: .teal,
            sortOrder: 0,
            updatedAt: Date(timeIntervalSince1970: 0),
            revision: 1,
            starterKey: "move-forward"
        )
    }

    static var acuteVisit: VisitTemplate {
        let components = [
            component("A2222222-2222-4222-8222-222222222201", "Greet and Smile!", minutes: 1),
            component("A2222222-2222-4222-8222-222222222202", "Understand the main concern", minutes: 3),
            component("A2222222-2222-4222-8222-222222222203", "Examine relevant body areas", minutes: 2),
            component("A2222222-2222-4222-8222-222222222204", "Discuss diagnosis and treatment plan", minutes: 3),
            component("A2222222-2222-4222-8222-222222222205", "EXIT room; place orders and prescriptions", minutes: 2),
            component("A2222222-2222-4222-8222-222222222206", "Tickler", minutes: 1),
            component("A2222222-2222-4222-8222-222222222207", "Nurse to lab or front", minutes: 1),
            component("A2222222-2222-4222-8222-222222222208", "Finish note", minutes: 2)
        ]
        return VisitTemplate(
            id: StarterIDs.acuteVisit,
            name: "Acute Visit",
            plannedDurationSeconds: 15 * 60,
            components: components,
            completionMessage: "Visit complete. Move forward!",
            roomExitComponentID: components[4].id,
            isFavorite: false,
            icon: .crossCase,
            accent: .indigo,
            sortOrder: 1,
            updatedAt: Date(timeIntervalSince1970: 0),
            revision: 1,
            starterKey: "acute-visit"
        )
    }

    static var adultPhysical: VisitTemplate {
        let components = [
            component("A3333333-3333-4333-8333-333333333301", "Greet and Smile!", minutes: 1),
            component("A3333333-3333-4333-8333-333333333302", "Understand concerns and interval history", minutes: 4),
            component("A3333333-3333-4333-8333-333333333303", "Review preventive history", minutes: 4),
            component("A3333333-3333-4333-8333-333333333304", "Complete physical examination", minutes: 4),
            component("A3333333-3333-4333-8333-333333333305", "Discuss cancer screenings", minutes: 4),
            component("A3333333-3333-4333-8333-333333333306", "Discuss vaccinations and prevention", minutes: 2),
            component("A3333333-3333-4333-8333-333333333307", "Summarize assessment and plan", minutes: 2),
            component("A3333333-3333-4333-8333-333333333308", "EXIT room; place and print orders", minutes: 2),
            component("A3333333-3333-4333-8333-333333333309", "Tickler", minutes: 1),
            component("A3333333-3333-4333-8333-333333333310", "Nurse handoff", minutes: 1),
            component("A3333333-3333-4333-8333-333333333311", "Finish note", minutes: 5)
        ]
        return VisitTemplate(
            id: StarterIDs.adultPhysical,
            name: "Adult Physical",
            plannedDurationSeconds: 30 * 60,
            components: components,
            completionMessage: "Dunzo! Good job!",
            roomExitComponentID: components[7].id,
            isFavorite: false,
            icon: .heart,
            accent: .sage,
            sortOrder: 2,
            updatedAt: Date(timeIntervalSince1970: 0),
            revision: 1,
            starterKey: "adult-physical"
        )
    }

    static var wellChild: VisitTemplate {
        let components = [
            component("A4444444-4444-4444-8444-444444444401", "Greet child and caregiver", minutes: 1),
            component("A4444444-4444-4444-8444-444444444402", "Understand parent or patient concerns", minutes: 3),
            component("A4444444-4444-4444-8444-444444444403", "Review growth and development", minutes: 3),
            component("A4444444-4444-4444-8444-444444444404", "Complete physical examination", minutes: 3),
            component("A4444444-4444-4444-8444-444444444405", "Provide anticipatory guidance", minutes: 2),
            component("A4444444-4444-4444-8444-444444444406", "Discuss vaccinations and plan", minutes: 1),
            component("A4444444-4444-4444-8444-444444444407", "EXIT room; enter orders", minutes: 2),
            component("A4444444-4444-4444-8444-444444444408", "Tickler", minutes: 1),
            component("A4444444-4444-4444-8444-444444444409", "Nurse handoff", minutes: 1),
            component("A4444444-4444-4444-8444-444444444410", "Finish note", minutes: 3)
        ]
        return VisitTemplate(
            id: StarterIDs.wellChild,
            name: "Well-Child Check",
            plannedDurationSeconds: 20 * 60,
            components: components,
            completionMessage: "Visit complete. Great work!",
            roomExitComponentID: components[6].id,
            isFavorite: false,
            icon: .figureChild,
            accent: .amber,
            sortOrder: 3,
            updatedAt: Date(timeIntervalSince1970: 0),
            revision: 1,
            starterKey: "well-child"
        )
    }

    static func blank(sortOrder: Int, at date: Date) -> VisitTemplate {
        let first = VisitComponent(title: "Greet and Smile!", durationSeconds: 2 * 60)
        return VisitTemplate(
            name: "New Visit",
            plannedDurationSeconds: 2 * 60,
            components: [first],
            completionMessage: "Visit complete. Move forward!",
            roomExitComponentID: nil,
            isFavorite: false,
            icon: .stethoscope,
            accent: .teal,
            sortOrder: sortOrder,
            updatedAt: date,
            revision: 1,
            starterKey: nil
        )
    }

    private static func component(_ id: String, _ title: String, minutes: Int) -> VisitComponent {
        VisitComponent(
            id: StarterIDs.uuid(id),
            title: title,
            durationSeconds: minutes * 60
        )
    }
}
