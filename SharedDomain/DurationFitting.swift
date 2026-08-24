import Foundation

enum FitError: Equatable, Sendable {
    case noComponents
    case totalTooSmall(minimumSeconds: Int)
    case invalidTotal

    var message: String {
        switch self {
        case .noComponents:
            return "Add at least one component before fitting."
        case .totalTooSmall(let minimumSeconds):
            return "This visit needs at least \(DurationFormatting.short(minimumSeconds)) so every component can be 30 seconds."
        case .invalidTotal:
            return "The planned duration must use 30-second increments."
        }
    }
}

enum DurationFitting {
    static func fit(durations: [Int], to totalSeconds: Int) -> Result<[Int], FitError> {
        guard !durations.isEmpty else { return .failure(.noComponents) }
        guard DurationMath.isValidIncrement(totalSeconds) else { return .failure(.invalidTotal) }
        let minimum = durations.count * DurationMath.minimumComponentSeconds
        guard totalSeconds >= minimum else {
            return .failure(.totalTooSmall(minimumSeconds: minimum))
        }

        let weights: [Double] = durations.map { duration in
            Double(max(duration, DurationMath.minimumComponentSeconds))
        }
        let weightSum = weights.reduce(0, +)
        var allocated = weights.map { weight in
            let raw = weight / weightSum * Double(totalSeconds)
            return DurationMath.clampedIncrement(Int(raw.rounded()), minimum: DurationMath.minimumComponentSeconds)
        }

        var difference = allocated.reduce(0, +) - totalSeconds
        var guardCount = 0
        while difference != 0 && guardCount < 10_000 {
            guardCount += 1
            if difference > 0 {
                guard let index = adjustableIndex(in: allocated, reducing: true) else { break }
                allocated[index] -= DurationMath.incrementSeconds
                difference -= DurationMath.incrementSeconds
            } else {
                guard let index = adjustableIndex(in: allocated, reducing: false) else { break }
                allocated[index] += DurationMath.incrementSeconds
                difference += DurationMath.incrementSeconds
            }
        }

        if allocated.reduce(0, +) != totalSeconds || allocated.contains(where: { $0 < DurationMath.minimumComponentSeconds }) {
            return equalDistribution(count: durations.count, totalSeconds: totalSeconds)
        }
        return .success(allocated)
    }

    static func applyFit(_ template: VisitTemplate) -> Result<VisitTemplate, FitError> {
        switch fit(durations: template.components.map(\.durationSeconds), to: template.plannedDurationSeconds) {
        case .failure(let error):
            return .failure(error)
        case .success(let durations):
            var next = template
            for index in next.components.indices {
                next.components[index].durationSeconds = durations[index]
            }
            return .success(next)
        }
    }

    static func usingComponentTotal(_ template: VisitTemplate) -> VisitTemplate {
        var next = template
        let allocated = max(template.allocatedSeconds, DurationMath.minimumPlannedSeconds)
        next.plannedDurationSeconds = DurationMath.clampedIncrement(allocated, minimum: DurationMath.minimumPlannedSeconds)
        return next
    }

    private static func adjustableIndex(in values: [Int], reducing: Bool) -> Int? {
        if reducing {
            return values.indices
                .filter { values[$0] >= DurationMath.minimumComponentSeconds + DurationMath.incrementSeconds }
                .max { values[$0] < values[$1] }
        }
        return values.indices.max { values[$0] < values[$1] }
    }

    private static func equalDistribution(count: Int, totalSeconds: Int) -> Result<[Int], FitError> {
        let minimum = count * DurationMath.minimumComponentSeconds
        guard totalSeconds >= minimum else {
            return .failure(.totalTooSmall(minimumSeconds: minimum))
        }
        var values = Array(repeating: DurationMath.minimumComponentSeconds, count: count)
        var remaining = totalSeconds - minimum
        var index = 0
        while remaining > 0 {
            values[index] += DurationMath.incrementSeconds
            remaining -= DurationMath.incrementSeconds
            index = (index + 1) % count
        }
        return .success(values)
    }
}
