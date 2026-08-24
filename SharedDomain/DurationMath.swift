import Foundation

enum DurationMath {
    static let incrementSeconds = 30
    static let minimumComponentSeconds = 30
    static let minimumPlannedSeconds = 30

    static func isValidIncrement(_ seconds: Int) -> Bool {
        seconds > 0 && seconds % incrementSeconds == 0
    }

    static func clampedIncrement(_ seconds: Int, minimum: Int = minimumComponentSeconds) -> Int {
        let snapped = Int((Double(seconds) / Double(incrementSeconds)).rounded()) * incrementSeconds
        return max(minimum, snapped)
    }

    static func addingIncrement(_ seconds: Int, steps: Int, minimum: Int = minimumComponentSeconds) -> Int {
        max(minimum, seconds + (steps * incrementSeconds))
    }

    static func minutesAndSeconds(from seconds: Int) -> (minutes: Int, seconds: Int) {
        (seconds / 60, seconds % 60)
    }

    static func displaySeconds(remaining: TimeInterval) -> Int {
        max(0, Int(ceil(remaining - 0.000_001)))
    }
}
