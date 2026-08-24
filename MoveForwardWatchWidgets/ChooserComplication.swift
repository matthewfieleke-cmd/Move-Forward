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
                glyph
                    .padding(9)
            }
            .widgetLabel("Templates")
        case .accessoryRectangular:
            HStack(spacing: 6) {
                glyph
                    .frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Move Forward")
                        .font(.headline)
                    Text("Choose a visit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        case .accessoryInline:
            // Inline complications only render SF Symbols alongside their text.
            Label("Move Forward", systemImage: "chevron.forward.circle")
        case .accessoryCorner:
            glyph
                .padding(4)
                .widgetLabel("Move Forward")
        default:
            glyph
        }
    }

    /// The app icon's mark, supplied as a template image so the watch face tints it.
    private var glyph: some View {
        Image("ComplicationGlyph")
            .resizable()
            .scaledToFit()
            .widgetAccentable()
            .accessibilityLabel("Move Forward")
    }
}

@main
struct MoveForwardWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MoveForwardWatchWidgets()
    }
}
