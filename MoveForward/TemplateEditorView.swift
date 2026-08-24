import SwiftUI

struct TemplateEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State var template: VisitTemplate
    @State private var showDeleteConfirm = false
    @State private var fitErrorMessage: String?

    private var validation: TemplateValidation {
        TemplateValidation.validate(template)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Template") {
                    TextField("Name", text: $template.name)
                    TextField("Completion message", text: $template.completionMessage, axis: .vertical)
                        .lineLimit(2...4)
                    Toggle("Favorite", isOn: $template.isFavorite)
                }

                Section("Look") {
                    iconGrid
                    accentRow
                }

                Section("Planned duration") {
                    DurationStepper(seconds: $template.plannedDurationSeconds, minimum: DurationMath.minimumPlannedSeconds)
                    allocationBanner
                    Button("Fit components to total") { applyFit() }
                    Button("Use component total") {
                        template = DurationFitting.usingComponentTotal(template)
                    }
                }

                Section("Components") {
                    ForEach($template.components) { $component in
                        ComponentEditorRow(
                            component: $component,
                            isRoomExit: template.roomExitComponentID == component.id,
                            startOffset: startOffset(for: component.id)
                        ) {
                            template.roomExitComponentID = template.roomExitComponentID == component.id ? nil : component.id
                        }
                    }
                    .onMove { source, destination in
                        template.components.move(fromOffsets: source, toOffset: destination)
                    }
                    .onDelete { offsets in
                        let removed = offsets.map { template.components[$0].id }
                        template.components.remove(atOffsets: offsets)
                        if let exitID = template.roomExitComponentID, removed.contains(exitID) {
                            template.roomExitComponentID = nil
                        }
                    }
                    Button("Add component", systemImage: "plus") {
                        template.components.append(VisitComponent(title: "New component", durationSeconds: 2 * 60))
                    }
                }

                Section("Timeline preview") {
                    timelinePreview
                }

                Section {
                    Button("Duplicate") {
                        store.duplicateTemplate(template)
                        dismiss()
                    }
                    Button("Delete template", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle(template.name.isEmpty ? "Template" : template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.saveTemplate(template)
                        dismiss()
                    }
                    .disabled(template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Could not fit", isPresented: Binding(
                get: { fitErrorMessage != nil },
                set: { if !$0 { fitErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { fitErrorMessage = nil }
            } message: {
                Text(fitErrorMessage ?? "")
            }
            .confirmationDialog("Delete this template?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.deleteTemplate(template)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .animation(Motion.value(reduceMotion, template.components.count), value: template.components.count)
        .onDisappear {
            let name = template.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                store.saveTemplate(template)
            }
        }
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
            ForEach(TemplateIcon.allCases, id: \.self) { icon in
                Button {
                    template.icon = icon
                } label: {
                    Image(systemName: icon.systemName)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(template.icon == icon ? .white : Palette.ink)
                        .background(template.icon == icon ? template.accent.color : Palette.cream, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .accessibilityLabel(icon.accessibilityLabel)
                .accessibilityAddTraits(template.icon == icon ? .isSelected : [])
            }
        }
        .buttonStyle(.plain)
    }

    private var accentRow: some View {
        HStack {
            ForEach(PaletteAccent.allCases, id: \.self) { accent in
                Button {
                    template.accent = accent
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if template.accent == accent {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .accessibilityLabel(accent.accessibilityLabel)
                .accessibilityAddTraits(template.accent == accent ? .isSelected : [])
            }
        }
    }

    private var allocationBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(validation.allocationSummary)
                .font(.subheadline)
            if !validation.isLaunchable {
                Text("Start is disabled until allocated time matches the planned visit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (validation.isBalanced ? Palette.teal.opacity(0.12) : Palette.amber.opacity(0.16)),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private var timelinePreview: some View {
        let timeline = TemplateTimeline.build(from: template)
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(timeline.steps) { step in
                HStack(alignment: .top) {
                    Text(DurationFormatting.offsetLabel(step.startOffsetSeconds))
                        .font(.countdown(15, weight: .semibold))
                        .frame(width: 52, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.subheadline.weight(step.isRoomExit ? .semibold : .regular))
                        Text(DurationFormatting.short(step.durationSeconds))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if step.isRoomExit {
                        Text("EXIT ROOM")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Palette.amber)
                            .accessibilityLabel("Room-exit milestone")
                    }
                }
            }
            HStack {
                Text(DurationFormatting.offsetLabel(template.plannedDurationSeconds))
                    .font(.countdown(15, weight: .semibold))
                    .frame(width: 52, alignment: .leading)
                Text(template.completionMessage)
                    .font(.subheadline)
            }
        }
    }

    private func startOffset(for componentID: UUID) -> Int {
        TemplateTimeline.build(from: template).steps.first(where: { $0.componentID == componentID })?.startOffsetSeconds ?? 0
    }

    private func applyFit() {
        switch DurationFitting.applyFit(template) {
        case .success(let fitted):
            template = fitted
        case .failure(let error):
            fitErrorMessage = error.message
        }
    }
}

private struct ComponentEditorRow: View {
    @Binding var component: VisitComponent
    var isRoomExit: Bool
    var startOffset: Int
    var toggleRoomExit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Component title", text: $component.title, axis: .vertical)
                    .lineLimit(1...3)
            }
            DurationStepper(seconds: $component.durationSeconds)
            HStack {
                Text("Starts at \(DurationFormatting.offsetLabel(startOffset))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isRoomExit ? "EXIT ROOM" : "Mark EXIT ROOM") {
                    toggleRoomExit()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(isRoomExit ? Palette.amber : Palette.tealDeep)
                .accessibilityLabel(isRoomExit ? "Room-exit milestone. Tap to remove." : "Mark as room-exit milestone")
            }
            if isRoomExit {
                Label("After this step, the visit continues outside the room.", systemImage: "door.left.hand.open")
                    .font(.caption)
                    .foregroundStyle(Palette.amber)
            }
        }
        .padding(.vertical, 6)
    }
}
