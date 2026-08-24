import AppIntents

struct OpenTemplateChooserIntent: AppIntent {
    static var title: LocalizedStringResource = "Choose Visit Template"
    static var description = IntentDescription("Open Move Forward’s template list. Nothing starts until you choose a visit.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        ChooserLaunch.request()
        return .result()
    }
}

struct MoveForwardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTemplateChooserIntent(),
            phrases: [
                "Choose a visit in \(.applicationName)",
                "Open visit templates in \(.applicationName)",
                "Start a visit with \(.applicationName)",
                "Show templates in \(.applicationName)"
            ],
            shortTitle: "Choose Template",
            systemImageName: "clock.badge.checkmark"
        )
    }
}
