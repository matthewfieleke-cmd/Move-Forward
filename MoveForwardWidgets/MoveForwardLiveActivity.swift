import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct MoveForwardWidgets: WidgetBundle {
    var body: some Widget {
        MoveForwardLiveActivity()
    }
}

struct MoveForwardLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VisitActivityAttributes.self) { context in
            lockScreen(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.templateName)
                        .font(.caption.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timer(context.state.visitEndDate)
                        .font(.countdown(16, weight: .semibold))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.componentTitle)
                        .font(.headline)
                        .foregroundStyle(context.state.isRoomExit ? Palette.amber : Palette.ink)
                        .lineLimit(2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: progress(context.state))
                        .tint(context.state.isRoomExit ? Palette.amber : Palette.teal)
                }
            } compactLeading: {
                Image(systemName: context.state.isRoomExit ? "door.left.hand.open" : "timer")
                    .foregroundStyle(context.state.isRoomExit ? Palette.amber : Palette.teal)
            } compactTrailing: {
                timer(context.state.visitEndDate)
                    .monospacedDigit()
                    .foregroundStyle(context.state.isRoomExit ? Palette.amber : .primary)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(Palette.teal)
            }
        }
    }

    private func lockScreen(context: ActivityViewContext<VisitActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.attributes.templateName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(context.state.componentTitle)
                .font(.headline)
                .foregroundStyle(context.state.isRoomExit ? Palette.amber : Palette.ink)
                .lineLimit(3)
            HStack {
                timer(context.state.componentEndDate)
                    .font(.countdown(28, weight: .semibold))
                Spacer()
                HStack(spacing: 4) {
                    Text("Visit")
                    timer(context.state.visitEndDate)
                }
                .font(.countdown(16))
                .foregroundStyle(.secondary)
            }
            ProgressView(value: progress(context.state))
                .tint(context.state.isRoomExit ? Palette.amber : Palette.teal)
        }
        .padding(16)
        // iOS 17 and later expect widgets and Live Activities to declare their background.
        .containerBackground(for: .widget) { Palette.cream }
    }

    private func timer(_ date: Date) -> Text {
        let now = Date()
        if date <= now {
            return Text("0:00")
        }
        return Text(timerInterval: now...date, countsDown: true)
    }

    private func progress(_ state: VisitActivityAttributes.ContentState) -> Double {
        let total = state.visitEndDate.timeIntervalSince(state.componentStartDate)
        guard total > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(state.componentStartDate)
        return min(1, max(0, elapsed / max(total, 0.001)))
    }
}
