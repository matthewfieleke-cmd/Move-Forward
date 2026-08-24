import SwiftUI
import WidgetKit
import AppIntents

struct ChooserTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChooserEntry {
        ChooserEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ChooserEntry) -> Void) {
        completion(ChooserEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChooserEntry>) -> Void) {
        completion(Timeline(entries: [ChooserEntry(date: Date())], policy: .never))
    }
}

struct ChooserEntry: TimelineEntry {
    let date: Date
}

struct MoveForwardWatchWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MoveForwardChooser", provider: ChooserTimelineProvider()) { _ in
            ChooserComplicationView()
                .widgetURL(URL(string: "moveforward://chooser"))
        }
        .configurationDisplayName("Move Forward")
        .description("Opens the visit template list. Nothing starts until you choose.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct ChooserComplicationView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "timer")
                    .font(.title3.weight(.semibold))
            }
            .widgetLabel("Templates")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("Move Forward", systemImage: "timer")
                    .font(.headline)
                Text("Choose a visit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .accessoryInline:
            Label("Choose visit", systemImage: "timer")
        case .accessoryCorner:
            Image(systemName: "timer")
                .widgetLabel("Visit")
        default:
            Image(systemName: "timer")
        }
    }
}

@main
struct MoveForwardWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MoveForwardWatchWidgets()
    }
}
