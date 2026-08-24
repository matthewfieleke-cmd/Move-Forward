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
        // A launcher has nothing to count down, so a single entry is enough.
        completion(Timeline(entries: [ChooserEntry(date: Date())], policy: .never))
    }
}

/// The app icon's mark: a progress ring broken at the room-exit checkpoint, with the
/// forward chevron inside.
///
/// Drawn with shapes rather than an image because watch faces render complications in
/// full colour, accented, and vibrant modes, and a bitmap does not survive all of them
/// or every face tint.
struct MoveForwardMark: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let stroke = max(side * 0.12, 1.5)
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.76)
                    .rotation(.degrees(-90))
                    .stroke(style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    .padding(stroke / 2)
                ForwardChevron()
                    .stroke(style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))
                    .frame(width: side * 0.24, height: side * 0.34)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel("Move Forward")
    }
}

struct ForwardChevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

struct ChooserComplicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MoveForwardChooser", provider: ChooserTimelineProvider()) { _ in
            ChooserComplicationView()
                .widgetURL(URL(string: "moveforward://chooser"))
                // watchOS 10 and later refuse to draw a widget that never declares a
                // container background.
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
                MoveForwardMark()
                    .padding(7)
            }
        case .accessoryRectangular:
            HStack(spacing: 6) {
                MoveForwardMark()
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
            // Inline complications only render SF Symbols beside their text.
            Label("Move Forward", systemImage: "chevron.forward.circle")
        case .accessoryCorner:
            MoveForwardMark()
                .padding(3)
                .widgetLabel("Move Forward")
        default:
            MoveForwardMark()
        }
    }
}

@main
struct MoveForwardWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChooserComplicationWidget()
    }
}
