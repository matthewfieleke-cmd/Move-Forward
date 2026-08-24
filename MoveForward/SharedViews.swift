import SwiftUI

struct TemplateRow: View {
    let template: VisitTemplate
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            iconBadge
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(Palette.ink)
                    if template.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Palette.teal)
                            .accessibilityLabel("Favorite")
                    }
                }
                Text("\(DurationFormatting.short(template.plannedDurationSeconds)) · \(template.components.count) components")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkMuted)
                if !compact {
                    MiniTimeline(template: template)
                }
                if let exit = template.roomExitComponent {
                    Label("EXIT ROOM · \(exit.title)", systemImage: "door.left.hand.open")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.amber)
                        .accessibilityLabel("Room-exit milestone: \(exit.title)")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(template.accent.color.opacity(0.16))
            Image(systemName: template.icon.systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(template.accent.color)
        }
        .frame(width: 48, height: 48)
        .accessibilityHidden(true)
    }
}

struct MiniTimeline: View {
    let template: VisitTemplate

    var body: some View {
        let timeline = TemplateTimeline.build(from: template)
        GeometryReader { geo in
            let total = CGFloat(max(timeline.steps.map(\.durationSeconds).reduce(0, +), 1))
            let spacing = CGFloat(3 * max(timeline.steps.count - 1, 0))
            HStack(spacing: 3) {
                ForEach(timeline.steps) { step in
                    Capsule()
                        .fill(step.isRoomExit ? Palette.amber : template.accent.color.opacity(0.55))
                        .frame(width: max(4, (geo.size.width - spacing) * CGFloat(step.durationSeconds) / total), height: 7)
                        .accessibilityLabel(step.isRoomExit ? "Exit room: \(step.title)" : step.title)
                }
            }
        }
        .frame(height: 8)
    }
}

struct DurationStepper: View {
    @Binding var seconds: Int
    var minimum = DurationMath.minimumComponentSeconds

    var body: some View {
        HStack(spacing: 12) {
            Button {
                seconds = DurationMath.addingIncrement(seconds, steps: -1, minimum: minimum)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Decrease duration by 30 seconds")

            Text(DurationFormatting.clock(seconds))
                .font(.countdown(28, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 88)
                .accessibilityLabel("Duration \(DurationFormatting.long(seconds))")

            Button {
                seconds = DurationMath.addingIncrement(seconds, steps: 1, minimum: minimum)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Increase duration by 30 seconds")
        }
    }
}

struct WatchStatusBanner: View {
    let status: WatchLinkStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.isReady ? "applewatch" : "applewatch.slash")
                .foregroundStyle(status.isReady ? Palette.teal : Palette.inkMuted)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.title)
                    .font(.subheadline.weight(.semibold))
                Text(status.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Palette.cream, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Palette.cardLight, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Palette.ink.opacity(0.06), radius: 12, y: 6)
    }
}
