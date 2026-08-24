import SwiftUI
import WidgetKit

struct ChooserEntry: TimelineEntry {
    let date: Date
}

struct ChooserTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChooserEntry {
        ChooserEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ChooserEntry) -> Void) {
        completion(ChooserEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChooserEntry>) -> Void) {
        // A launcher has nothing to count down, so one entry is enough.
        completion(Timeline(entries: [ChooserEntry(date: Date())], policy: .never))
    }
}

struct ChooserComplicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MoveForwardChooser", provider: ChooserTimelineProvider()) { _ in
            ChooserComplicationView()
                .widgetURL(URL(string: "moveforward://chooser"))
                // watchOS 10 and later refuse to render a widget that never declares
                // a container background.
                .containerBackground(.clear, for: .widget)
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
                glyph.padding(9)
            }
        case .accessoryRectangular:
            HStack(spacing: 6) {
                glyph.frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Move Forward")
                        .font(.headline)
                    Text("Choose a visit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        case .accessoryInline:
            // Inline complications only render SF Symbols beside their text.
            Label("Move Forward", systemImage: "chevron.forward.circle")
        case .accessoryCorner:
            glyph
                .padding(3)
                .widgetLabel("Move Forward")
        default:
            glyph
        }
    }

    /// The app icon's mark, shipped as a template image so the watch face tints it.
    private var glyph: some View {
        Image("ComplicationGlyph")
            .resizable()
            .scaledToFit()
            .widgetAccentable()
            .accessibilityLabel("Move Forward")
    }
}

@main
struct MoveForwardWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChooserComplicationWidget()
    }
}
