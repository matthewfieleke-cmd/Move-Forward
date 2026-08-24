import XCTest
@testable import MoveForward

final class FixedClock: Clock, @unchecked Sendable {
    var current: Date
    init(_ current: Date) { self.current = current }
    func now() -> Date { current }
}

final class MoveForwardTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    func testStarterTemplatesHaveExactlyFour() {
        XCTAssertEqual(StarterTemplates.all.count, 4)
        XCTAssertEqual(Set(StarterTemplates.all.map(\.id)).count, 4)
    }

    func testStarterDurationsSumToPlannedTotals() {
        for template in StarterTemplates.all {
            XCTAssertEqual(template.allocatedSeconds, template.plannedDurationSeconds, template.name)
            XCTAssertTrue(TemplateValidation.validate(template).isLaunchable, template.name)
            XCTAssertTrue(template.components.allSatisfy { DurationMath.isValidIncrement($0.durationSeconds) })
            XCTAssertTrue(DurationMath.isValidIncrement(template.plannedDurationSeconds))
        }
    }

    func testMoveForwardTemplateIsExactlyTwentyMinutes() {
        XCTAssertEqual(StarterTemplates.moveForward.plannedDurationSeconds, 20 * 60)
        XCTAssertEqual(StarterTemplates.moveForward.allocatedSeconds, 20 * 60)
        XCTAssertEqual(StarterTemplates.moveForward.completionMessage, "Dunzo! Good job!")
    }

    func testMoveForwardComponentBoundaries() {
        let timeline = TemplateTimeline.build(from: StarterTemplates.moveForward)
        XCTAssertEqual(
            timeline.boundaryOffsetsSeconds(),
            [0, 60, 300, 420, 660, 780, 840, 900, 1200]
        )
        XCTAssertEqual(timeline.steps.map(\.title), [
            "Greet and Smile!",
            "Understand their concerns, open-ended questions",
            "Examine relevant body areas",
            "Provide diagnosis and treatment plan",
            "EXIT room, place orders for medications/imaging/labs, and print off labs",
            "Tickler",
            "Nurse walk to lab or to front",
            "Finish note and on to next!"
        ])
        XCTAssertEqual(timeline.steps[4].isRoomExit, true)
    }

    func testAcuteVisitIsExactlyFifteenMinutes() {
        XCTAssertEqual(StarterTemplates.acuteVisit.plannedDurationSeconds, 15 * 60)
        XCTAssertEqual(StarterTemplates.acuteVisit.allocatedSeconds, 15 * 60)
    }

    func testAdultPhysicalIsExactlyThirtyMinutes() {
        XCTAssertEqual(StarterTemplates.adultPhysical.plannedDurationSeconds, 30 * 60)
        XCTAssertEqual(StarterTemplates.adultPhysical.allocatedSeconds, 30 * 60)
    }

    func testWellChildIsExactlyTwentyMinutes() {
        XCTAssertEqual(StarterTemplates.wellChild.plannedDurationSeconds, 20 * 60)
        XCTAssertEqual(StarterTemplates.wellChild.allocatedSeconds, 20 * 60)
    }

    func testDurationsHonorThirtySecondIncrements() {
        XCTAssertTrue(DurationMath.isValidIncrement(30))
        XCTAssertTrue(DurationMath.isValidIncrement(90))
        XCTAssertFalse(DurationMath.isValidIncrement(0))
        XCTAssertFalse(DurationMath.isValidIncrement(45))
        XCTAssertEqual(DurationMath.addingIncrement(60, steps: 1), 90)
        XCTAssertEqual(DurationMath.addingIncrement(30, steps: -1), 30)
    }

    func testValidationIdentifiesUnderallocation() {
        var template = StarterTemplates.moveForward
        template.plannedDurationSeconds = 25 * 60
        let validation = TemplateValidation.validate(template)
        XCTAssertFalse(validation.isLaunchable)
        XCTAssertTrue(validation.issues.contains(where: { $0.kind == .underallocated }))
        XCTAssertEqual(validation.unallocatedSeconds, 5 * 60)
    }

    func testValidationIdentifiesOverallocation() {
        var template = StarterTemplates.moveForward
        template.components[0].durationSeconds = 6 * 60
        let validation = TemplateValidation.validate(template)
        XCTAssertFalse(validation.isLaunchable)
        XCTAssertTrue(validation.issues.contains(where: { $0.kind == .overallocated }))
        XCTAssertEqual(validation.excessSeconds, 5 * 60)
    }

    func testReorderingUpdatesCumulativeOffsets() {
        var template = StarterTemplates.moveForward
        template.components.swapAt(0, 1)
        let timeline = TemplateTimeline.build(from: template)
        XCTAssertEqual(timeline.steps[0].title, "Understand their concerns, open-ended questions")
        XCTAssertEqual(timeline.steps[0].startOffsetSeconds, 0)
        XCTAssertEqual(timeline.steps[1].title, "Greet and Smile!")
        XCTAssertEqual(timeline.steps[1].startOffsetSeconds, 4 * 60)
    }

    func testRoomExitMilestoneFollowsComponentIdentityAfterReorder() {
        var template = StarterTemplates.moveForward
        let exitID = template.roomExitComponentID
        template.components.swapAt(0, 4)
        let timeline = TemplateTimeline.build(from: template)
        XCTAssertEqual(template.roomExitComponentID, exitID)
        XCTAssertEqual(timeline.steps[0].isRoomExit, true)
        XCTAssertEqual(timeline.steps[0].componentID, exitID)
        XCTAssertEqual(timeline.steps[4].isRoomExit, false)
    }

    func testActiveSessionUsesStableTemplateSnapshot() {
        var template = StarterTemplates.moveForward
        let session = SessionEngine.start(template: template, at: start, origin: .phone)
        template.components[0].title = "Changed later"
        template.plannedDurationSeconds = 10 * 60
        XCTAssertEqual(session.templateSnapshot.components[0].title, "Greet and Smile!")
        XCTAssertEqual(session.templateSnapshot.plannedDurationSeconds, 20 * 60)
        let projection = SessionEngine.projection(session: session, now: start)
        XCTAssertEqual(projection.componentTitle, "Greet and Smile!")
    }

    func testEndingASessionDoesNotCountAsCompleted() {
        let session = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .phone)
        let ended = SessionEngine.endManually(session, at: start.addingTimeInterval(90))
        let result = SessionEngine.reconcile(
            session: ended,
            now: start.addingTimeInterval(TimeInterval(21 * 60)),
            alreadyCountedSessionIDs: []
        )
        XCTAssertEqual(result.session.state, .ended)
        XCTAssertNil(result.completion)
    }

    func testRestartCancelsAndReplacesThePriorSession() {
        let first = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .watch)
        let pair = SessionEngine.restart(
            replacing: first,
            template: StarterTemplates.acuteVisit,
            at: start.addingTimeInterval(30),
            origin: .watch
        )
        XCTAssertEqual(pair.ended.state, .ended)
        XCTAssertEqual(pair.ended.id, first.id)
        XCTAssertEqual(pair.started.state, .active)
        XCTAssertNotEqual(pair.started.id, first.id)
        XCTAssertEqual(pair.started.templateSnapshot.id, StarterTemplates.acuteVisit.id)
        XCTAssertTrue(pair.started.plannedEndedAtMatchesSnapshot())
    }

    func testNaturalCompletionIsCountedExactlyOnce() {
        let session = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .phone)
        let now = start.addingTimeInterval(TimeInterval(20 * 60 + 1))
        let first = SessionEngine.reconcile(session: session, now: now, alreadyCountedSessionIDs: [])
        XCTAssertEqual(first.session.state, .completed)
        XCTAssertNotNil(first.completion)
        XCTAssertEqual(first.completion?.sessionID, session.id)

        let second = SessionEngine.reconcile(
            session: first.session,
            now: now.addingTimeInterval(30),
            alreadyCountedSessionIDs: [session.id]
        )
        XCTAssertNil(second.completion)
        XCTAssertEqual(second.session.state, .completed)
    }

    func testDuplicateSyncEventsDoNotDoubleCountCompletion() {
        let session = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .watch)
        var completed = session
        completed.state = .completed
        completed.endedAt = session.plannedEndedAt
        completed.revision += 1
        let visit = CompletedVisit(
            sessionID: session.id,
            templateID: session.templateSnapshot.id,
            templateName: session.templateSnapshot.name,
            completedAt: session.plannedEndedAt,
            plannedDurationSeconds: session.plannedDurationSeconds
        )
        let local = PersistedSnapshot(
            schemaVersion: 1,
            templates: StarterTemplates.all,
            session: session,
            completedVisits: [visit],
            settings: .default,
            templatesRevision: 1
        )
        let incoming = SyncEnvelope.make(
            kind: .sessionComplete,
            origin: .watch,
            at: start.addingTimeInterval(1200),
            session: completed,
            completedVisits: [visit]
        )
        let merged = SyncMerger.merge(local: local, incoming: incoming, localDevice: .phone)
        XCTAssertEqual(merged.snapshot.completedVisits.filter { $0.sessionID == session.id }.count, 1)
    }

    func testRemainingTimeReconstructsFromPersistedTimestamps() {
        let session = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .phone)
        let now = start.addingTimeInterval(6 * 60)
        let projection = SessionEngine.projection(session: session, now: now)
        XCTAssertEqual(projection.componentTitle, "Examine relevant body areas")
        XCTAssertEqual(DurationMath.displaySeconds(remaining: projection.componentRemaining), 60)
        XCTAssertEqual(DurationMath.displaySeconds(remaining: projection.visitRemaining), 14 * 60)
        XCTAssertEqual(projection.componentIndex, 2)
        XCTAssertFalse(projection.isPostRoom)
        XCTAssertEqual(DurationMath.displaySeconds(remaining: projection.timeUntilRoomExit ?? -1), 5 * 60)
    }

    func testExpiredComponentCheckpointsAreNotRescheduled() {
        let session = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .watch)
        let now = start.addingTimeInterval(12 * 60)
        let alerts = NotificationPlanner.futureAlerts(for: session, now: now)
        let offsets = alerts.map { Int($0.fireDate.timeIntervalSince(start)) }
        XCTAssertEqual(offsets, [13 * 60, 14 * 60, 15 * 60, 20 * 60])
        XCTAssertFalse(offsets.contains(0))
        XCTAssertFalse(offsets.contains(60))
        XCTAssertFalse(offsets.contains(5 * 60))
        XCTAssertFalse(offsets.contains(7 * 60))
        XCTAssertFalse(offsets.contains(11 * 60))
        XCTAssertEqual(alerts.last?.title, "Dunzo! Good job!")
    }

    @MainActor
    func testStaleNotificationsAreRemovedAfterEndingOrRestarting() async {
        let scheduler = MockNotificationScheduler()
        let controller = SessionNotificationController(scheduler: scheduler, schedulesSystemNotifications: true)
        let session = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .watch)
        _ = await controller.reschedule(session: session, now: start)
        let pendingAfterStart = await scheduler.pendingIdentifiers()
        XCTAssertFalse(pendingAfterStart.isEmpty)

        await controller.cancel(sessionID: session.id, knownIdentifiers: session.notificationIdentifiers)
        let pendingAfterCancel = await scheduler.pendingIdentifiers()
        XCTAssertTrue(pendingAfterCancel.isEmpty)
    }

    func testFavoritesAndTemplateChangesPersist() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mf-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = PersistenceStore(fileURL: url)
        var snapshot = store.load()
        XCTAssertEqual(snapshot.templates.count, 4)
        guard let index = snapshot.templates.firstIndex(where: { $0.id == StarterIDs.moveForward }) else {
            return XCTFail("Missing starter template")
        }
        snapshot.templates[index].isFavorite = false
        snapshot.templates[index].name = "Clinic Flow"
        snapshot.templatesRevision = 2
        try store.save(snapshot)

        let loaded = PersistenceStore(fileURL: url).load()
        let saved = loaded.templates.first { $0.id == StarterIDs.moveForward }
        XCTAssertEqual(saved?.isFavorite, false)
        XCTAssertEqual(saved?.name, "Clinic Flow")
        XCTAssertEqual(loaded.templatesRevision, 2)
    }

    func testFitPreservesThirtySecondIncrementsAndNonZeroComponents() {
        var template = StarterTemplates.moveForward
        template.plannedDurationSeconds = 18 * 60
        switch DurationFitting.applyFit(template) {
        case .failure(let error):
            XCTFail(error.message)
        case .success(let fitted):
            XCTAssertEqual(fitted.allocatedSeconds, 18 * 60)
            XCTAssertTrue(fitted.components.allSatisfy { $0.durationSeconds >= 30 })
            XCTAssertTrue(fitted.components.allSatisfy { DurationMath.isValidIncrement($0.durationSeconds) })
        }
    }

    func testUsingComponentTotalAdoptsAllocatedTime() {
        var template = StarterTemplates.moveForward
        template.plannedDurationSeconds = 25 * 60
        let updated = DurationFitting.usingComponentTotal(template)
        XCTAssertEqual(updated.plannedDurationSeconds, template.allocatedSeconds)
        XCTAssertTrue(TemplateValidation.validate(updated).isLaunchable)
    }

    func testSettingsFromEarlierBuildsStillDecode() throws {
        let legacy = """
        {"appearance":"system","hasCompletedOnboarding":true}
        """
        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(legacy.utf8))
        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertFalse(settings.livesActivityEnabled)
    }

    func testLiveActivityStaysOffUntilEnabled() {
        XCTAssertFalse(AppSettings.default.livesActivityEnabled)
        var settings = AppSettings.default
        settings.showsLiveActivity = true
        XCTAssertTrue(settings.livesActivityEnabled)
    }

    func testFitErrorIsAnError() {
        let error: Error = FitError.noComponents
        XCTAssertTrue(error is FitError)
    }

    func testPostRoomProjectionAfterExitBegins() {
        let session = SessionEngine.start(template: StarterTemplates.moveForward, at: start, origin: .phone)
        let duringExit = SessionEngine.projection(session: session, now: start.addingTimeInterval(11 * 60 + 10))
        XCTAssertTrue(duringExit.isRoomExitComponent)
        XCTAssertNil(duringExit.timeUntilRoomExit)

        let afterExit = SessionEngine.projection(session: session, now: start.addingTimeInterval(13 * 60 + 10))
        XCTAssertTrue(afterExit.isPostRoom)
        XCTAssertEqual(afterExit.componentTitle, "Tickler")
    }
}
