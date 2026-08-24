import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ActiveSessionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmEnd = false
    @State private var confirmRestart = false
    @State private var lastHapticIndex: Int?

    var body: some View {
        Group {
            if let projection = store.currentProjection, store.session != nil {
                content(projection)
            } else {
                ContentUnavailableView("No active visit", systemImage: "timer", description: Text("Start a template from Timers."))
            }
        }
        .background(Palette.cream.ignoresSafeArea())
        .navigationTitle(store.currentProjection?.templateName ?? "Visit")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: store.currentProjection?.componentIndex) { _, newValue in
            guard let newValue, store.currentProjection?.phase == .running else { return }
            if lastHapticIndex != newValue {
                lastHapticIndex = newValue
                playTransitionHaptic()
            }
        }
        .confirmationDialog("End this visit?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End visit", role: .destructive) {
                Task { await store.endVisit(countAsCompleted: false) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remaining alerts will be cancelled. This will not count as a completed visit.")
        }
        .confirmationDialog("Restart this visit?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Restart") {
                Task { await store.restartVisit() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The current timer will be replaced from the beginning and will not count as complete.")
        }
    }

    @ViewBuilder
    private func content(_ projection: LiveProjection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if projection.phase == .completed || projection.phase == .ended {
                    completionCard(projection)
                } else {
                    runningCard(projection)
                }
                controls(projection)
            }
            .padding(20)
        }
        .animation(Motion.value(reduceMotion, projection.componentIndex), value: projection.componentIndex)
    }

    private func runningCard(_ projection: LiveProjection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(projection.componentIndex + 1) of \(projection.componentCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if projection.isRoomExitComponent {
                    Label("EXIT ROOM", systemImage: "door.left.hand.open")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Palette.amber)
                } else if projection.isPostRoom {
                    Label("After the room", systemImage: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Palette.tealDeep)
                }
            }
            Text(projection.componentTitle)
                .font(.title.weight(.semibold))
                .foregroundStyle(projection.isRoomExitComponent ? Palette.amber : Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(DurationFormatting.clock(projection.componentRemaining))
                .font(.countdown(64, weight: .medium))
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.6)
                .accessibilityLabel("Component remaining \(DurationFormatting.long(DurationMath.displaySeconds(remaining: projection.componentRemaining)))")
            ProgressView(value: projection.componentProgress)
                .tint(projection.isRoomExitComponent ? Palette.amber : Palette.teal)
            HStack {
                VStack(alignment: .leading) {
                    Text("Visit remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(DurationFormatting.clock(projection.visitRemaining))
                        .font(.countdown(28, weight: .semibold))
                }
                Spacer()
                if let remaining = projection.timeUntilRoomExit {
                    VStack(alignment: .trailing) {
                        Text("Until EXIT ROOM")
                            .font(.caption)
                            .foregroundStyle(Palette.amber)
                        Text(DurationFormatting.clock(remaining))
                            .font(.countdown(22, weight: .semibold))
                            .foregroundStyle(Palette.amber)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Time remaining until room exit \(DurationFormatting.long(DurationMath.displaySeconds(remaining: remaining)))")
                }
            }
            ProgressView(value: projection.visitProgress)
                .tint(Palette.tealDeep)
        }
        .modifier(CardBackground())
    }

    private func completionCard(_ projection: LiveProjection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(projection.phase == .ended ? "Visit ended" : "Visit complete")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.tealDeep)
            Text(projection.completionMessage)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("The planned visit time has finished. Start the next template when you are ready.")
                .foregroundStyle(.secondary)
        }
        .modifier(CardBackground())
        .accessibilityElement(children: .combine)
    }

    private func controls(_ projection: LiveProjection) -> some View {
        VStack(spacing: 12) {
            if projection.phase == .running {
                Button(role: .destructive) { confirmEnd = true } label: {
                    Label("End", systemImage: "stop.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Button { confirmRestart = true } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            Button {
                store.showChooser = true
            } label: {
                Label("Start Next Template", systemImage: "forward.end.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.teal)
        }
    }

    private func playTransitionHaptic() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
