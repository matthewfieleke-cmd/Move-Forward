import Foundation

enum DurationFormatting {
    static func clock(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let minutes = clamped / 60
        let remainder = clamped % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    static func clock(_ remaining: TimeInterval) -> String {
        clock(DurationMath.displaySeconds(remaining: remaining))
    }

    static func short(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let minutes = clamped / 60
        let remainder = clamped % 60
        if remainder == 0 {
            return minutes == 1 ? "1 min" : "\(minutes) min"
        }
        if minutes == 0 {
            return "\(remainder)s"
        }
        return String(format: "%d:%02d", minutes, remainder)
    }

    static func long(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let minutes = clamped / 60
        let remainder = clamped % 60
        switch (minutes, remainder) {
        case (0, let s):
            return "\(s) seconds"
        case (let m, 0):
            return m == 1 ? "1 minute" : "\(m) minutes"
        default:
            return "\(minutes) min \(remainder) sec"
        }
    }

    static func offsetLabel(_ seconds: Int) -> String {
        clock(seconds)
    }
}
