import Combine
import Foundation
#if os(watchOS)
import WatchKit
#endif

@MainActor
final class AppStore: ObservableObject {
    @Published var templates: [VisitTemplate]
    @Published var session: VisitSession?
    @Published var completedVisits: [CompletedVisit]
    @Published var settings: AppSettings
    @Published var templatesRevision: Int
    @Published var watchStatus: WatchLinkStatus = .unknown
    @Published var now: Date
    @Published var showChooser = false
    @Published var lastErrorMessage: String?
    @Published var notificationStatus: String = "Unknown"
    @Published var notificationsNeedSystemSettings = false
    @Published var testAlertStatus: String?

    let localDevice: DeviceOrigin
    let persistence: PersistenceStore
    let notifications: SessionNotificationController
    let connectivity: ConnectivityService
    let liveActivity = LiveActivityController()
    let clock: Clock

    private var timer: Timer?

    init(
        localDevice: DeviceOrigin,
        persistence: PersistenceStore,
        notifications: SessionNotificationController,
        connectivity: ConnectivityService,
        clock: Clock = SystemClock()
    ) {
        self.localDevice = localDevice
        self.persistence = persistence
        self.notifications = notifications
        self.connectivity = connectivity
        self.clock = clock
        self.now = clock.now()

        let snapshot = persistence.load()
        templates = snapshot.templates.sorted { $0.sortOrder < $1.sortOrder }
        session = snapshot.session
        completedVisits = snapshot.completedVisits
        settings = snapshot.settings
        templatesRevision = snapshot.templatesRevision

        connectivity.delegate = self
        connectivity.activate(localDevice: localDevice)
        updateClockSubscription()
        NotificationCenter.default.addObserver(forName: ChooserLaunch.notification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.showChooser = true
            }
        }
        if ChooserLaunch.consume() {
            showChooser = true
        }
        Task { await bootstrap() }
    }

    var sortedTemplates: [VisitTemplate] {
        templates.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
            if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var favoriteTemplates: [VisitTemplate] {
        sortedTemplates.filter(\.isFavorite)
    }

    var currentProjection: LiveProjection? {
        guard let session else { return nil }
        return SessionEngine.projection(session: session, now: now)
    }

    var todayStats: TodayStats {
        StatisticsEngine.summarize(visits: completedVisits, now: now)
    }

    var activeSession: VisitSession? {
        guard let session, session.state == .active else { return nil }
        return session
    }

    func bootstrap() async {
        _ = await notifications.scheduler.requestAuthorization()
        await refreshNotificationStatus()
        await reconcileSession()
        if localDevice == .watch, let session, session.state == .active {
            _ = await notifications.reschedule(session: session, now: now)
        }
        pushFullState(preferImmediate: false)
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        persist()
    }

    func saveTemplate(_ template: VisitTemplate) {
        var next = template
        next.revision += 1
        next.updatedAt = clock.now()
        if let index = templates.firstIndex(where: { $0.id == next.id }) {
            templates[index] = next
        } else {
            next.sortOrder = (templates.map(\.sortOrder).max() ?? -1) + 1
            templates.append(next)
        }
        templatesRevision += 1
        persist()
        pushTemplates()
    }

    func deleteTemplate(_ template: VisitTemplate) {
        templates.removeAll { $0.id == template.id }
        templatesRevision += 1
        persist()
        pushTemplates()
    }

    func duplicateTemplate(_ template: VisitTemplate) {
        let copy = template.duplicating(
            name: "\(template.name) Copy",
            sortOrder: (templates.map(\.sortOrder).max() ?? 0) + 1,
            at: clock.now()
        )
        templates.append(copy)
        templatesRevision += 1
        persist()
        pushTemplates()
    }

    func toggleFavorite(_ template: VisitTemplate) {
        guard var current = templates.first(where: { $0.id == template.id }) else { return }
        current.isFavorite.toggle()
        saveTemplate(current)
    }

    func moveTemplate(_ template: VisitTemplate, by delta: Int) {
        var ordered = templates.sorted { $0.sortOrder < $1.sortOrder }
        guard let index = ordered.firstIndex(where: { $0.id == template.id }) else { return }
        let destination = index + delta
        guard ordered.indices.contains(destination) else { return }
        ordered.move(fromOffsets: IndexSet(integer: index), toOffset: destination > index ? destination + 1 : destination)
        for (order, item) in ordered.enumerated() {
            if let existing = templates.firstIndex(where: { $0.id == item.id }) {
                templates[existing].sortOrder = order
            }
        }
        templatesRevision += 1
        persist()
        pushTemplates()
    }

    func requestNotificationPermission() async {
        _ = await notifications.scheduler.requestAuthorization()
        await refreshNotificationStatus()
    }

    func canStart(_ template: VisitTemplate) -> Bool {
        TemplateValidation.validate(template).isLaunchable
    }

    func startVisit(_ template: VisitTemplate, replacingExisting: Bool = false) async {
        guard canStart(template) else {
            lastErrorMessage = "This template is not balanced yet. Adjust times before starting."
            return
        }
        if let session, session.state == .active {
            guard replacingExisting else { return }
            await endVisit(countAsCompleted: false, sync: false)
        }
        let started = SessionEngine.start(template: template, at: clock.now(), origin: localDevice)
        session = started
        persist()
        await notifications.reschedule(session: started, now: clock.now())
        startLiveActivityIfEnabled(started)
        playStartHaptic()
        updateClockSubscription()
        if localDevice == .phone {
            connectivity.markPendingAck()
        }
        pushEnvelope(
            SyncEnvelope.make(
                kind: .sessionStart,
                origin: localDevice,
                at: clock.now(),
                templates: templates,
                templatesRevision: templatesRevision,
                session: started,
                completedVisits: completedVisits
            ),
            preferImmediate: true
        )
        now = clock.now()
    }

    func endVisit(countAsCompleted: Bool, sync: Bool = true) async {
        guard var session else { return }
        if countAsCompleted {
            let result = SessionEngine.reconcile(
                session: session,
                now: max(clock.now(), session.plannedEndedAt),
                alreadyCountedSessionIDs: Set(completedVisits.map(\.sessionID))
            )
            session = result.session
            if let completion = result.completion {
                completedVisits.append(completion)
            }
        } else {
            session = SessionEngine.endManually(session, at: clock.now())
        }
        await notifications.cancel(sessionID: session.id, knownIdentifiers: session.notificationIdentifiers)
        liveActivity.end(sessionID: session.id)
        self.session = session
        persist()
        updateClockSubscription()
        if sync {
            pushEnvelope(
                SyncEnvelope.make(
                    kind: countAsCompleted ? .sessionComplete : .sessionEnd,
                    origin: localDevice,
                    at: clock.now(),
                    session: session,
                    completedVisits: completedVisits
                ),
                preferImmediate: true
            )
        }
    }

    func restartVisit() async {
        guard let session else { return }
        let template = templates.first(where: { $0.id == session.templateSnapshot.id }) ?? session.templateSnapshot
        let pair = SessionEngine.restart(replacing: session, template: template, at: clock.now(), origin: localDevice)
        await notifications.cancel(sessionID: session.id, knownIdentifiers: session.notificationIdentifiers)
        liveActivity.end(sessionID: session.id)
        self.session = pair.started
        persist()
        await notifications.reschedule(session: pair.started, now: clock.now())
        startLiveActivityIfEnabled(pair.started)
        playStartHaptic()
        now = clock.now()
        updateClockSubscription()
        pushEnvelope(
            SyncEnvelope.make(
                kind: .sessionRestart,
                origin: localDevice,
                at: clock.now(),
                session: pair.started,
                completedVisits: completedVisits
            ),
            preferImmediate: true
        )
    }

    /// Clears a finished session from this device so the UI returns to the template list.
    /// Active sessions are never cleared this way.
    func dismissFinishedSession() {
        guard let finished = session, finished.state != .active else { return }
        session = nil
        persist()
        updateClockSubscription()
    }

    func restoreStarterTemplates() {
        var existing = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        for starter in StarterTemplates.all {
            existing[starter.id] = starter
        }
        templates = existing.values.sorted { $0.sortOrder < $1.sortOrder }
        templatesRevision += 1
        persist()
        pushTemplates()
    }

    func resetAllData() async {
        if let session {
            await notifications.cancel(sessionID: session.id, knownIdentifiers: session.notificationIdentifiers)
            liveActivity.end(sessionID: session.id)
        }
        templates = StarterTemplates.all
        session = nil
        completedVisits = []
        settings = .default
        settings.hasCompletedOnboarding = true
        templatesRevision += 1
        persist()
        updateClockSubscription()
        pushFullState(preferImmediate: true)
    }

    func setAppearance(_ appearance: AppearancePreference) {
        settings.appearance = appearance
        persist()
    }

    func setShowsLiveActivity(_ value: Bool) {
        settings.showsLiveActivity = value
        persist()
        guard let session else { return }
        if value {
            startLiveActivityIfEnabled(session)
        } else {
            liveActivity.end(sessionID: session.id)
        }
    }

    func sendTestWatchAlert() {
        guard localDevice == .phone else {
            Task { await presentTestAlert() }
            return
        }
        guard watchStatus.isReady else {
            testAlertStatus = watchStatus.detail
            return
        }
        testAlertStatus = connectivity.isImmediatelyReachable
            ? "Sent. Your Apple Watch should tap in a moment."
            : "Queued. Raise your wrist or open Move Forward on the watch and it will arrive."
        pushEnvelope(
            SyncEnvelope.make(kind: .testAlert, origin: localDevice, at: clock.now()),
            preferImmediate: true
        )
    }

    func handleOpenURL(_ url: URL) {
        let text = url.absoluteString.lowercased()
        if text.contains("chooser") || url.host == "chooser" {
            showChooser = true
            ChooserLaunch.request()
        }
    }

    func setSuppressesForegroundAlerts(_ value: Bool) {
        if let scheduler = notifications.scheduler as? UserNotificationScheduler {
            scheduler.suppressesForegroundAlerts = value
        }
    }

    func reconcileSession() async {
        now = clock.now()
        guard let session else {
            updateClockSubscription()
            return
        }
        let result = SessionEngine.reconcile(
            session: session,
            now: clock.now(),
            alreadyCountedSessionIDs: Set(completedVisits.map(\.sessionID))
        )
        if result.session != session || result.completion != nil {
            self.session = result.session
            if let completion = result.completion {
                completedVisits.append(completion)
                await notifications.cancel(sessionID: session.id, knownIdentifiers: session.notificationIdentifiers)
                liveActivity.end(sessionID: session.id)
                persist()
                pushEnvelope(
                    SyncEnvelope.make(
                        kind: .sessionComplete,
                        origin: localDevice,
                        at: clock.now(),
                        session: result.session,
                        completedVisits: completedVisits
                    ),
                    preferImmediate: false
                )
            } else {
                persist()
            }
        }
        if result.session.state == .active, settings.livesActivityEnabled {
            liveActivity.update(session: result.session, now: clock.now())
        }
        updateClockSubscription()
    }

    func refreshNotificationStatus() async {
        let status = await notifications.scheduler.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            notificationStatus = "Allowed"
        case .denied:
            notificationStatus = "Denied"
        case .notDetermined:
            notificationStatus = "Not requested"
        @unknown default:
            notificationStatus = "Unknown"
        }
        notificationsNeedSystemSettings = status != .notDetermined
    }

    private func persist() {
        let snapshot = PersistedSnapshot(
            schemaVersion: 1,
            templates: templates,
            session: session,
            completedVisits: completedVisits,
            settings: settings,
            templatesRevision: templatesRevision
        )
        try? persistence.save(snapshot)
    }

    private func pushTemplates() {
        pushEnvelope(
            SyncEnvelope.make(
                kind: .templates,
                origin: localDevice,
                at: clock.now(),
                templates: templates,
                templatesRevision: templatesRevision
            ),
            preferImmediate: false
        )
    }

    private func pushFullState(preferImmediate: Bool) {
        pushEnvelope(
            SyncEnvelope.make(
                kind: .fullState,
                origin: localDevice,
                at: clock.now(),
                templates: templates,
                templatesRevision: templatesRevision,
                session: session,
                completedVisits: completedVisits
            ),
            preferImmediate: preferImmediate
        )
    }

    private func pushEnvelope(_ envelope: SyncEnvelope, preferImmediate: Bool) {
        connectivity.send(envelope, preferImmediate: preferImmediate)
    }

    private func applyIncoming(_ envelope: SyncEnvelope) async {
        if envelope.kind == .testAlert {
            await presentTestAlert()
            return
        }
        let snapshot = PersistedSnapshot(
            schemaVersion: 1,
            templates: templates,
            session: session,
            completedVisits: completedVisits,
            settings: settings,
            templatesRevision: templatesRevision
        )
        let result = SyncMerger.merge(local: snapshot, incoming: envelope, localDevice: localDevice)
        guard result.didChange else {
            if envelope.kind == .ack { watchStatus = .synced }
            return
        }
        for endedID in result.endedSessionIDs {
            await notifications.cancel(sessionID: endedID)
            liveActivity.end(sessionID: endedID)
        }
        templates = result.snapshot.templates
        session = result.snapshot.session
        completedVisits = result.snapshot.completedVisits
        settings = result.snapshot.settings
        templatesRevision = result.snapshot.templatesRevision
        persist()
        updateClockSubscription()
        if result.shouldReschedule, let session, session.state == .active {
            _ = await notifications.reschedule(session: session, now: clock.now())
            startLiveActivityIfEnabled(session)
            if localDevice == .watch {
                let scheduled = NotificationPlanner.futureAlerts(for: session, now: clock.now()).count
                pushEnvelope(
                    SyncEnvelope.make(
                        kind: .ack,
                        origin: .watch,
                        at: clock.now(),
                        ackSessionID: session.id,
                        ackScheduledCount: scheduled
                    ),
                    preferImmediate: true
                )
            }
        }
        if envelope.kind == .ack {
            watchStatus = .synced
        }
        now = clock.now()
    }

    private func presentTestAlert() async {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #endif
        guard notifications.schedulesSystemNotifications else { return }
        let alert = PlannedAlert(
            identifier: "mf.test.\(UUID().uuidString)",
            fireDate: clock.now().addingTimeInterval(2),
            title: "Move Forward",
            body: "Test wrist cue. Silent Mode plus haptics keeps this quiet.",
            isCompletion: false,
            componentID: nil
        )
        await notifications.scheduler.add(alerts: [alert])
    }

    private func playStartHaptic() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif
    }

    private func startLiveActivityIfEnabled(_ session: VisitSession) {
        guard settings.livesActivityEnabled else { return }
        liveActivity.start(session: session, now: clock.now())
    }

    /// The clock only ticks while a visit is running. Without this every screen would
    /// redraw continuously, which made scrolling stutter.
    private func updateClockSubscription() {
        guard session?.state == .active else {
            timer?.invalidate()
            timer = nil
            return
        }
        guard timer == nil else { return }
        let ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                await self.reconcileSession()
            }
        }
        RunLoop.main.add(ticker, forMode: .common)
        timer = ticker
    }
}

extension AppStore: ConnectivityDelegate {
    func connectivityDidReceive(_ envelope: SyncEnvelope) {
        Task { await applyIncoming(envelope) }
    }

    func connectivityDidUpdateStatus(_ status: WatchLinkStatus) {
        watchStatus = status
    }
}
