import Foundation

enum TemplateIcon: String, Codable, CaseIterable, Sendable, Hashable {
    case stethoscope
    case heart
    case figureChild = "figure.child"
    case sunHorizon = "sun.horizon"
    case crossCase = "cross.case"
    case clipboard = "list.clipboard"
    case clockBadge = "clock.badge.checkmark"
    case sparkle = "sparkles"
    case person2 = "person.2"
    case wave = "hand.wave"

    var systemName: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .stethoscope: return "Stethoscope"
        case .heart: return "Heart"
        case .figureChild: return "Child"
        case .sunHorizon: return "Horizon"
        case .crossCase: return "Medical case"
        case .clipboard: return "Clipboard"
        case .clockBadge: return "Clock"
        case .sparkle: return "Sparkles"
        case .person2: return "People"
        case .wave: return "Wave"
        }
    }
}

enum PaletteAccent: String, Codable, CaseIterable, Sendable, Hashable {
    case teal
    case indigo
    case sage
    case slate
    case amber

    var accessibilityLabel: String {
        switch self {
        case .teal: return "Teal"
        case .indigo: return "Indigo"
        case .sage: return "Sage"
        case .slate: return "Slate"
        case .amber: return "Amber"
        }
    }
}

struct VisitComponent: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var durationSeconds: Int

    init(
        id: UUID = UUID(),
        title: String,
        durationSeconds: Int
    ) {
        self.id = id
        self.title = title
        self.durationSeconds = durationSeconds
    }
}

struct VisitTemplate: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var plannedDurationSeconds: Int
    var components: [VisitComponent]
    var completionMessage: String
    var roomExitComponentID: UUID?
    var isFavorite: Bool
    var icon: TemplateIcon
    var accent: PaletteAccent
    var sortOrder: Int
    var updatedAt: Date
    var revision: Int
    var starterKey: String?

    init(
        id: UUID = UUID(),
        name: String,
        plannedDurationSeconds: Int,
        components: [VisitComponent],
        completionMessage: String,
        roomExitComponentID: UUID? = nil,
        isFavorite: Bool = false,
        icon: TemplateIcon = .stethoscope,
        accent: PaletteAccent = .teal,
        sortOrder: Int = 0,
        updatedAt: Date = Date(),
        revision: Int = 1,
        starterKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.plannedDurationSeconds = plannedDurationSeconds
        self.components = components
        self.completionMessage = completionMessage
        self.roomExitComponentID = roomExitComponentID
        self.isFavorite = isFavorite
        self.icon = icon
        self.accent = accent
        self.sortOrder = sortOrder
        self.updatedAt = updatedAt
        self.revision = revision
        self.starterKey = starterKey
    }

    var allocatedSeconds: Int {
        components.reduce(0) { $0 + $1.durationSeconds }
    }

    var roomExitComponent: VisitComponent? {
        guard let roomExitComponentID else { return nil }
        return components.first { $0.id == roomExitComponentID }
    }

    var roomExitIndex: Int? {
        guard let roomExitComponentID else { return nil }
        return components.firstIndex { $0.id == roomExitComponentID }
    }

    mutating func bumpRevision(at date: Date) {
        revision += 1
        updatedAt = date
    }

    func duplicating(name: String, sortOrder: Int, at date: Date) -> VisitTemplate {
        var idMap: [UUID: UUID] = [:]
        let copied = components.map { component -> VisitComponent in
            let newID = UUID()
            idMap[component.id] = newID
            return VisitComponent(id: newID, title: component.title, durationSeconds: component.durationSeconds)
        }
        let newExit = roomExitComponentID.flatMap { idMap[$0] }
        return VisitTemplate(
            id: UUID(),
            name: name,
            plannedDurationSeconds: plannedDurationSeconds,
            components: copied,
            completionMessage: completionMessage,
            roomExitComponentID: newExit,
            isFavorite: false,
            icon: icon,
            accent: accent,
            sortOrder: sortOrder,
            updatedAt: date,
            revision: 1,
            starterKey: nil
        )
    }
}

enum DeviceOrigin: String, Codable, Sendable, Hashable {
    case phone
    case watch
}

enum SessionState: String, Codable, Sendable, Hashable {
    case active
    case completed
    case ended
}

struct VisitSession: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var templateSnapshot: VisitTemplate
    var startedAt: Date
    var plannedEndedAt: Date
    var state: SessionState
    var origin: DeviceOrigin
    var revision: Int
    var notificationIdentifiers: [String]
    var endedAt: Date?

    var plannedDurationSeconds: Int {
        templateSnapshot.plannedDurationSeconds
    }

    var templateName: String {
        templateSnapshot.name
    }

    func plannedEndedAtMatchesSnapshot() -> Bool {
        abs(plannedEndedAt.timeIntervalSince(startedAt) - TimeInterval(plannedDurationSeconds)) < 0.001
    }
}

struct CompletedVisit: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var sessionID: UUID
    var templateID: UUID
    var templateName: String
    var completedAt: Date
    var plannedDurationSeconds: Int

    init(
        id: UUID? = nil,
        sessionID: UUID,
        templateID: UUID,
        templateName: String,
        completedAt: Date,
        plannedDurationSeconds: Int
    ) {
        self.id = id ?? sessionID
        self.sessionID = sessionID
        self.templateID = templateID
        self.templateName = templateName
        self.completedAt = completedAt
        self.plannedDurationSeconds = plannedDurationSeconds
    }
}

enum AppearancePreference: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

struct AppSettings: Codable, Equatable, Sendable {
    var hasCompletedOnboarding: Bool
    var appearance: AppearancePreference
    var lastWatchAckAt: Date?
    var lastWatchAckSessionID: UUID?
    var lastWatchScheduledCount: Int?

    static let `default` = AppSettings(
        hasCompletedOnboarding: false,
        appearance: .system,
        lastWatchAckAt: nil,
        lastWatchAckSessionID: nil,
        lastWatchScheduledCount: nil
    )
}

struct PersistedSnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var templates: [VisitTemplate]
    var session: VisitSession?
    var completedVisits: [CompletedVisit]
    var settings: AppSettings
    var templatesRevision: Int

    static func empty() -> PersistedSnapshot {
        PersistedSnapshot(
            schemaVersion: 1,
            templates: [],
            session: nil,
            completedVisits: [],
            settings: .default,
            templatesRevision: 0
        )
    }
}
