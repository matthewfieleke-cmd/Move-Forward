import Foundation

struct TemplateUsage: Identifiable, Equatable, Sendable {
    var templateID: UUID
    var templateName: String
    var count: Int
    var id: UUID { templateID }
}

struct DayCount: Identifiable, Equatable, Sendable {
    var day: Date
    var count: Int
    var id: Date { day }
}

struct TodayStats: Equatable, Sendable {
    var completedToday: Int
    var mostUsed: [TemplateUsage]
    var recentToday: [CompletedVisit]
    var sevenDayTrend: [DayCount]
}

enum StatisticsEngine {
    static func summarize(
        visits: [CompletedVisit],
        now: Date,
        calendar: Calendar = .current
    ) -> TodayStats {
        let todayVisits = visits
            .filter { calendar.isDate($0.completedAt, inSameDayAs: now) }
            .sorted { $0.completedAt > $1.completedAt }

        var counts: [UUID: (name: String, count: Int)] = [:]
        for visit in visits {
            var entry = counts[visit.templateID] ?? (visit.templateName, 0)
            entry.name = visit.templateName
            entry.count += 1
            counts[visit.templateID] = entry
        }

        let mostUsed = counts
            .map { TemplateUsage(templateID: $0.key, templateName: $0.value.name, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.templateName < rhs.templateName
            }

        let startOfToday = calendar.startOfDay(for: now)
        let trend: [DayCount] = (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { return nil }
            let count = visits.filter { calendar.isDate($0.completedAt, inSameDayAs: day) }.count
            return DayCount(day: day, count: count)
        }

        return TodayStats(
            completedToday: todayVisits.count,
            mostUsed: mostUsed,
            recentToday: todayVisits,
            sevenDayTrend: trend
        )
    }
}
