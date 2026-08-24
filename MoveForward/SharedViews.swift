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
                    Label(exit.title, systemImage: "door.left.hand.open")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.amber)
                        .lineLimit(2)
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

/// Drawn in a single Canvas pass. Nested GeometryReaders in a scrolling list
/// re-measure constantly and made the timers list stutter.
struct MiniTimeline: View {
    let template: VisitTemplate
    var height: CGFloat = 8

    var body: some View {
        let steps = TemplateTimeline.build(from: template).steps
        let total = CGFloat(max(steps.reduce(0) { $0 + $1.durationSeconds }, 1))
        let accent = template.accent.color.opacity(0.55)
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            let gap: CGFloat = 3
            let usable = max(size.width - gap * CGFloat(max(steps.count - 1, 0)), 1)
            var x: CGFloat = 0
            for step in steps {
                let width = max(3, usable * CGFloat(step.durationSeconds) / total)
                let rect = CGRect(x: x, y: 0, width: width, height: size.height)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: size.height / 2),
                    with: .color(step.isRoomExit ? Palette.amber : accent)
                )
                x += width + gap
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Timeline of \(steps.count) components")
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
                .font(.subheadline)
                .foregroundStyle(status.isReady ? Palette.teal : Palette.amber)
            VStack(alignment: .leading, spacing: 3) {
                Text("Sync status: \(status.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text(status.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Palette.cardLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Palette.amber.opacity(status.isReady ? 0 : 0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Palette.cardLight, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Palette.ink.opacity(0.05), radius: 5, y: 2)
    }
}
