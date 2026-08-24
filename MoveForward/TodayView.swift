import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(store.todayStats.completedToday)")
                            .font(.countdown(72, weight: .medium))
                            .foregroundStyle(Palette.tealDeep)
                        Text(store.todayStats.completedToday == 1 ? "visit completed today" : "visits completed today")
                            .font(.title3)
                            .foregroundStyle(Palette.inkMuted)
                        Text("Only visits that run to their planned end are counted.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .modifier(CardBackground())

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most used")
                            .font(.headline)
                        if store.todayStats.mostUsed.isEmpty {
                            Text("Completed visits will appear here.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.todayStats.mostUsed.prefix(5)) { usage in
                                HStack {
                                    Text(usage.templateName)
                                    Spacer()
                                    Text("\(usage.count)")
                                        .font(.countdown(20, weight: .semibold))
                                        .foregroundStyle(Palette.tealDeep)
                                }
                            }
                        }
                    }
                    .modifier(CardBackground())

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent today")
                            .font(.headline)
                        if store.todayStats.recentToday.isEmpty {
                            Text("No completed visits yet today.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.todayStats.recentToday) { visit in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(visit.templateName)
                                        Text(visit.completedAt.formatted(date: .omitted, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(DurationFormatting.short(visit.plannedDurationSeconds))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .modifier(CardBackground())

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 days")
                            .font(.headline)
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(store.todayStats.sevenDayTrend) { day in
                                VStack {
                                    Capsule()
                                        .fill(Palette.teal.opacity(day.count == 0 ? 0.2 : 0.9))
                                        .frame(height: barHeight(day.count))
                                    Text(day.day.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel("\(day.day.formatted(.dateTime.weekday(.wide))), \(day.count) completed")
                            }
                        }
                        .frame(height: 120, alignment: .bottom)
                    }
                    .modifier(CardBackground())
                }
                .padding(20)
            }
            .background(Palette.cream.ignoresSafeArea())
            .navigationTitle("Today")
        }
    }

    private func barHeight(_ count: Int) -> CGFloat {
        let maxCount = max(store.todayStats.sevenDayTrend.map(\.count).max() ?? 1, 1)
        return CGFloat(16 + (70 * count / maxCount))
    }
}
