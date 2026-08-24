import SwiftUI
import WatchKit

struct WatchRootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var dismissedSessionID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if showsSession {
                    WatchSessionView(onDismissFinished: dismissFinished)
                } else {
                    WatchTemplateListView()
                }
            }
        }
        .sheet(isPresented: $store.showChooser) {
            NavigationStack {
                WatchTemplateListView(isChooser: true)
            }
            .environmentObject(store)
        }
        .task {
            await store.bootstrap()
        }
    }

    /// A manually ended visit returns straight to the list. A naturally completed visit
    /// stays on screen until it is acknowledged.
    private var showsSession: Bool {
        guard let session = store.session, session.id != dismissedSessionID else { return false }
        return session.state == .active || session.state == .completed
    }

    private func dismissFinished() {
        dismissedSessionID = store.session?.id
    }
}

struct WatchTemplateListView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var isChooser = false
    @State private var pendingTemplate: VisitTemplate?

    var body: some View {
        List {
            if let projection = store.currentProjection, store.activeSession != nil {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Visit running", systemImage: "timer")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.teal)
                        Text(projection.componentTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Section {
                ForEach(store.sortedTemplates) { template in
                    Button {
                        pendingTemplate = template
                    } label: {
                        WatchTemplateRow(template: template)
                    }
                }
            } header: {
                Text(store.activeSession == nil ? "Templates" : "Start another")
            } footer: {
                Text("One visit runs at a time.")
                    .font(.caption2)
            }
        }
        .navigationTitle("Move Forward")
        .sheet(item: $pendingTemplate) { template in
            NavigationStack {
                WatchStartView(template: template) {
                    pendingTemplate = nil
                    if isChooser { dismiss() }
                }
            }
            .environmentObject(store)
        }
    }
}

struct WatchTemplateRow: View {
    let template: VisitTemplate

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: template.icon.systemName)
                .foregroundStyle(template.accent.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .lineLimit(2)
                    if template.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Palette.teal)
                            .accessibilityLabel("Favorite")
                    }
                }
                Text("\(DurationFormatting.short(template.plannedDurationSeconds)) · \(template.components.count) steps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct WatchStartView: View {
    @EnvironmentObject private var store: AppStore
    let template: VisitTemplate
    var onFinish: () -> Void
    @State private var confirmReplace = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(template.name)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(DurationFormatting.long(template.plannedDurationSeconds)) · \(template.components.count) steps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let first = template.components.first {
                    Text("Begins with “\(first.title)”")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if store.activeSession != nil {
                    Label("A visit is already running", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(Palette.amber)
                }
                Button {
                    start()
                } label: {
                    Text(store.activeSession == nil ? "Start" : "Replace and start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.canStart(template) ? Palette.teal : Palette.slate)
                .disabled(!store.canStart(template))
                if !store.canStart(template) {
                    Text("Balance this template on iPhone before starting.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Start")
        .confirmationDialog("Replace the current visit?", isPresented: $confirmReplace, titleVisibility: .visible) {
            Button("Replace", role: .destructive) {
                Task {
                    await store.startVisit(template, replacingExisting: true)
                    onFinish()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The running timer ends without counting as completed.")
        }
    }

    private func start() {
        if store.activeSession != nil {
            confirmReplace = true
        } else {
            Task {
                await store.startVisit(template)
                onFinish()
            }
        }
    }
}

struct WatchSessionView: View {
    @EnvironmentObject private var store: AppStore
    var onDismissFinished: () -> Void
    @State private var confirmEnd = false
    @State private var confirmRestart = false
    @State private var lastHapticIndex: Int?
    @State private var hapticSessionID: UUID?
    @State private var completedSessionID: UUID?

    var body: some View {
        Group {
            if let projection = store.currentProjection {
                sessionContent(projection)
            } else {
                ProgressView()
            }
        }
        .onChange(of: store.currentProjection?.componentIndex) { _, newIndex in
            handleComponentChange(newIndex)
        }
        .onChange(of: store.currentProjection?.phase) { _, phase in
            handlePhaseChange(phase)
        }
        .confirmationDialog("End this visit?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End visit", role: .destructive) {
                Task {
                    await store.endVisit(countAsCompleted: false)
                    onDismissFinished()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remaining alerts are cancelled. This does not count as completed.")
        }
        .confirmationDialog("Restart this visit?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Restart") {
                Task { await store.restartVisit() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The timer starts over and does not count as completed.")
        }
    }

    @ViewBuilder
    private func sessionContent(_ projection: LiveProjection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if projection.phase == .completed || projection.phase == .ended {
                    completionContent(projection)
                } else {
                    runningContent(projection)
                }
                controls(projection)
            }
        }
        .navigationTitle(projection.templateName)
    }

    @ViewBuilder
    private func runningContent(_ projection: LiveProjection) -> some View {
        HStack {
            Text("\(projection.componentIndex + 1) of \(projection.componentCount)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if projection.isRoomExitComponent {
                Text("EXIT ROOM")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.amber)
                    .accessibilityLabel("Room-exit milestone")
            } else if projection.isPostRoom {
                Text("After the room")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.teal)
            }
        }
        Text(projection.componentTitle)
            .font(.headline)
            .foregroundStyle(projection.isRoomExitComponent ? Palette.amber : .primary)
            .fixedSize(horizontal: false, vertical: true)
        Text(DurationFormatting.clock(projection.componentRemaining))
            .font(.countdown(38, weight: .semibold))
            .minimumScaleFactor(0.7)
            .accessibilityLabel("Step remaining \(DurationFormatting.long(DurationMath.displaySeconds(remaining: projection.componentRemaining)))")
        ProgressView(value: projection.componentProgress)
            .tint(projection.isRoomExitComponent ? Palette.amber : Palette.teal)
        Text("Visit \(DurationFormatting.clock(projection.visitRemaining)) left")
            .font(.caption)
            .foregroundStyle(.secondary)
        if let untilExit = projection.timeUntilRoomExit {
            Text("EXIT ROOM in \(DurationFormatting.clock(untilExit))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.amber)
                .accessibilityLabel("Time until room exit \(DurationFormatting.long(DurationMath.displaySeconds(remaining: untilExit)))")
        }
        if let session = store.session {
            Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened)) · ends \(session.plannedEndedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func completionContent(_ projection: LiveProjection) -> some View {
        Text(projection.phase == .ended ? "Visit ended" : "Visit complete")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Palette.teal)
        Text(projection.completionMessage)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func controls(_ projection: LiveProjection) -> some View {
        if projection.phase == .running {
            Button("End", role: .destructive) { confirmEnd = true }
            Button("Restart") { confirmRestart = true }
        }
        Button("Start Next Template") {
            store.showChooser = true
        }
        if projection.phase != .running {
            Button("Templates") {
                onDismissFinished()
            }
        }
    }

    /// The first observed index is the one already on screen, so only later transitions tap.
    /// A new or restarted session already plays its own start haptic.
    private func handleComponentChange(_ newIndex: Int?) {
        guard let newIndex, store.currentProjection?.phase == .running else { return }
        let sessionID = store.session?.id
        defer {
            lastHapticIndex = newIndex
            hapticSessionID = sessionID
        }
        guard hapticSessionID == sessionID, let previous = lastHapticIndex, previous != newIndex else { return }
        WKInterfaceDevice.current().play(.notification)
    }

    private func handlePhaseChange(_ phase: LiveProjection.Phase?) {
        guard phase == .completed, let sessionID = store.session?.id, completedSessionID != sessionID else { return }
        completedSessionID = sessionID
        WKInterfaceDevice.current().play(.success)
    }
}
