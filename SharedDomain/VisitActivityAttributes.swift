import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct VisitActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var componentTitle: String
        var componentIndex: Int
        var componentCount: Int
        var componentStartDate: Date
        var componentEndDate: Date
        var visitEndDate: Date
        var isRoomExit: Bool
        var isPostRoom: Bool
        var phaseRaw: String
    }

    var templateName: String
    var sessionID: UUID
}
#endif
