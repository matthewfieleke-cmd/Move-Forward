import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            Group {
                if store.currentProjection != nil, store.session?.state == .active || store.session?.state == .completed {
                    WatchSessionView()
                } else {
                    WatchTemplateListView()
                }
            }
        }
        .sheet(isPresented: $store.showChooser) {
            WatchTemplateListView(isChooser: true)
                .environmentObject(store)
        }
        .task {
            await store.bootstrap()
        }
    }
}

struct WatchTemplateListView: View {
    @EnvironmentObject private var store: AppStore
    var isChooser = false
    @State private var pendingTemplate: VisitTemplate?

    var body: some View {
        List {
            if !isChooser {
                Text("Choose a template. Nothing starts until you tap Start.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
            ForEach(store.sortedTemplates) { template in
                NavigationLink {
                    WatchStartView(template: template)
                } label: {
                    WatchTemplateRow(template: template)
                }
            }
        }
        .navigationTitle("Move Forward")
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
                HStack {
                    Text(template.name)
                        .font(.headline)
                    if template.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Palette.teal)
                            .accessibilityLabel("Favorite")
                    }
                }
                Text(DurationFormatting.short(template.plannedDurationSeconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct WatchStartView: View {
    @EnvironmentObject private var store: AppStore
    let template: VisitTemplate
    @State private var confirmReplace = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label(template.name, systemImage: template.icon.systemName)
                    .font(.headline)
                Text(DurationFormatting.long(template.plannedDurationSeconds))
                    .foregroundStyle(.secondary)
                Text("\(template.components.count) components")
                    .foregroundStyle(.secondary)
                Button {
                    start()
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.canStart(template) ? Palette.teal : Palette.slate)
                .disabled(!store.canStart(template))
            }
        }
        .navigationTitle("Start")
        .confirmationDialog("Replace the current visit?", isPresented: $confirmReplace, titleVisibility: .visible) {
            Button("Start new visit", role: .destructive) {
                Task { await store.startVisit(template, replacingExisting: true) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The current timer will end without counting as completed.")
        }
    }

    private func start() {
        if store.activeSession != nil {
            confirmReplace = true
        } else {
            Task { await store.startVisit(template) }
        }
    }
}

struct WatchSessionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmEnd = false
    @State private var confirmRestart = false

    var body: some View {
        Group {
            if let projection = store.currentProjection {
                sessionContent(projection)
            } else {
                WatchTemplateListView()
            }
        }
    }

    @ViewBuilder
    private func sessionContent(_ projection: LiveProjection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if projection.phase == .completed || projection.phase == .ended {
                    Text(projection.phase == .ended ? "Visit ended" : "Visit complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.teal)
                    Text(projection.completionMessage)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack {
                        Text("\(projection.componentIndex + 1) of \(projection.componentCount)")
                            .font(.caption.weight(.semibold))
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
                        .font(.countdown(34, weight: .semibold))
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel("Component remaining \(DurationFormatting.long(DurationMath.displaySeconds(remaining: projection.componentRemaining)))")
                    ProgressView(value: projection.componentProgress)
                        .tint(projection.isRoomExitComponent ? Palette.amber : Palette.teal)
                    Text("Visit \(DurationFormatting.clock(projection.visitRemaining))")
                        .font(.countdown(18, weight: .medium))
                        .foregroundStyle(.secondary)
                    if let remaining = projection.timeUntilRoomExit {
                        Text("EXIT ROOM in \(DurationFormatting.clock(remaining))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.amber)
                            .accessibilityLabel("Time remaining until room exit \(DurationFormatting.long(DurationMath.displaySeconds(remaining: remaining)))")
                    }
                }

                if projection.phase == .running {
                    Button("End", role: .destructive) { confirmEnd = true }
                    Button("Restart") { confirmRestart = true }
                }
                Button("Start Next Template") {
                    store.showChooser = true
                }
            }
        }
        .confirmationDialog("End this visit?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End visit", role: .destructive) {
                Task { await store.endVisit(countAsCompleted: false) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Restart this visit?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Restart") {
                Task { await store.restartVisit() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
