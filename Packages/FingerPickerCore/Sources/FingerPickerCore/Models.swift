/// Stable identity for one finger during one app run. Assigned by the touch layer from a
/// monotonically increasing counter and never reused, so stale/duplicate touches cannot alias.
public struct TouchID: Hashable, Sendable, Comparable {
    public let rawValue: Int
    public init(_ rawValue: Int) { self.rawValue = rawValue }
    public static func < (l: TouchID, r: TouchID) -> Bool { l.rawValue < r.rawValue }
}

/// Position in the play surface, normalized to 0...1 on both axes (bounds-relative).
public struct NormalizedPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// One finger taking part in a round. `colorIndex` indexes the shared palette (see `Palette`).
public struct Participant: Equatable, Sendable, Identifiable {
    public let id: TouchID
    public var point: NormalizedPoint
    public let colorIndex: Int
    public init(id: TouchID, point: NormalizedPoint, colorIndex: Int) {
        self.id = id; self.point = point; self.colorIndex = colorIndex
    }
}

/// Immutable record created exactly once at lock time. The winner is decided here,
/// before any animation exists.
public struct Round: Equatable, Sendable {
    public let participants: [Participant]   // frozen
    public let winnerID: TouchID
    public let winnerPoint: NormalizedPoint
    public let winnerColorIndex: Int
    public init(participants: [Participant], winnerID: TouchID) {
        precondition(participants.contains { $0.id == winnerID }, "winner must be a participant")
        let w = participants.first { $0.id == winnerID }!
        self.participants = participants
        self.winnerID = winnerID
        self.winnerPoint = w.point
        self.winnerColorIndex = w.colorIndex
    }
}
