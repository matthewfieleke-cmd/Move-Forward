import SwiftUI

struct TimersView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editorTemplate: VisitTemplate?
    @State private var creatingNew = false
    @State private var templatePendingStart: VisitTemplate?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let projection = store.currentProjection, store.activeSession != nil {
                        NavigationLink {
                            ActiveSessionView()
                        } label: {
                            ActiveVisitBanner(projection: projection)
                        }
                        .buttonStyle(.plain)
                    }
                    WatchStatusBanner(status: store.watchStatus)
                    if !store.sortedTemplates.filter(\.isFavorite).isEmpty {
                        Text("Favorites")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                        ForEach(store.sortedTemplates.filter(\.isFavorite)) { template in
                            templateCard(template)
                        }
                    }
                    Text("All templates")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    ForEach(store.sortedTemplates) { template in
                        templateCard(template)
                    }
                }
                .padding(20)
            }
            .background(Palette.cream.ignoresSafeArea())
            .navigationTitle("Move Forward")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creatingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add template")
                }
            }
            .sheet(item: $editorTemplate) { template in
                TemplateEditorView(template: template)
                    .environmentObject(store)
            }
            .sheet(isPresented: $creatingNew) {
                TemplateEditorView(
                    template: StarterTemplates.blank(
                        sortOrder: (store.templates.map(\.sortOrder).max() ?? 0) + 1,
                        at: store.now
                    )
                )
                .environmentObject(store)
            }
            .confirmationDialog(
                "Replace the current visit?",
                isPresented: Binding(
                    get: { templatePendingStart != nil },
                    set: { if !$0 { templatePendingStart = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Start new visit", role: .destructive) {
                    if let template = templatePendingStart {
                        Task { await store.startVisit(template, replacingExisting: true) }
                        templatePendingStart = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    templatePendingStart = nil
                }
            } message: {
                Text("The current timer will end without counting as a completed visit.")
            }
            .alert("Can't start visit", isPresented: Binding(
                get: { store.lastErrorMessage != nil },
                set: { if !$0 { store.lastErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { store.lastErrorMessage = nil }
            } message: {
                Text(store.lastErrorMessage ?? "")
            }
        }
    }

    private func start(_ template: VisitTemplate) {
        if store.activeSession != nil {
            templatePendingStart = template
        } else {
            Task { await store.startVisit(template) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Visit timers")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Palette.ink)
            Text("Set the sequence. Start. Keep moving through the room and after.")
                .font(.body)
                .foregroundStyle(Palette.inkMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private func templateCard(_ template: VisitTemplate) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            TemplateRow(template: template)
            HStack {
                Button {
                    start(template)
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.canStart(template) ? Palette.teal : Palette.slate)
                .disabled(!store.canStart(template))

                Button {
                    editorTemplate = template
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
            }
        }
        .modifier(CardBackground())
        .contextMenu {
            Button {
                store.toggleFavorite(template)
            } label: {
                Label(template.isFavorite ? "Remove Favorite" : "Favorite", systemImage: template.isFavorite ? "star.slash" : "star")
            }
            Button {
                store.duplicateTemplate(template)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Button {
                store.moveTemplate(template, by: -1)
            } label: {
                Label("Move Up", systemImage: "arrow.up")
            }
            Button {
                store.moveTemplate(template, by: 1)
            } label: {
                Label("Move Down", systemImage: "arrow.down")
            }
            Button(role: .destructive) {
                store.deleteTemplate(template)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct ActiveVisitBanner: View {
    let projection: LiveProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(projection.phase == .completed ? "Visit complete" : "Visit in progress")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.tealDeep)
            Text(projection.componentTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(projection.isRoomExitComponent ? Palette.amber : Palette.ink)
            HStack {
                Text(DurationFormatting.clock(projection.componentRemaining))
                    .font(.countdown(34, weight: .semibold))
                Spacer()
                Text("Visit \(DurationFormatting.clock(projection.visitRemaining))")
                    .font(.countdown(20))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: projection.visitProgress)
                .tint(projection.isRoomExitComponent ? Palette.amber : Palette.teal)
        }
        .modifier(CardBackground())
        .accessibilityElement(children: .combine)
    }
}
