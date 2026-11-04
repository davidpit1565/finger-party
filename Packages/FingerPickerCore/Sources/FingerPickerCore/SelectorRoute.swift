import Foundation

/// Visual-only route for the "selector" that hops between fingers. It is generated
/// AFTER the winner is known and is built backwards from the winner, so it cannot
/// influence the outcome and always ends on the stored winner.
public struct SelectorStep: Equatable, Sendable {
    public let id: TouchID
    /// Seconds to dwell on this finger before hopping to the next.
    public let dwell: Double
}

public enum SelectorRoute {
    /// - Parameters:
    ///   - participants: frozen participants in stable order (sorted by id internally).
    ///   - winnerID: precomputed winner.
    ///   - totalDuration: approximate total travel time in seconds.
    ///   - minSteps: minimum number of hops (guarantees a few visible loops).
    public static func make(participants: [Participant], winnerID: TouchID,
                            totalDuration: Double = 2.4, minSteps: Int = 14) -> [SelectorStep] {
        let ordered = participants.sorted { $0.id < $1.id }
        guard let wIdx = ordered.firstIndex(where: { $0.id == winnerID }) else { return [] }
        let n = ordered.count
        // Enough hops for >= 2 full loops, never fewer than minSteps.
        let steps = max(minSteps, n * 2 + 2)
        // Walk backwards from the winner around the ring, so the last step is the winner.
        var ids: [TouchID] = []
        for i in 0..<steps {
            let offsetFromEnd = steps - 1 - i
            let idx = ((wIdx - offsetFromEnd) % n + n) % n
            ids.append(ordered[idx].id)
        }
        // Ease-out dwell times: fast at first, slow at the end.
        let weights = (0..<steps).map { i -> Double in
            let t = Double(i) / Double(steps - 1)
            return 0.35 + 2.65 * t * t * t   // cubic ease-out in time
        }
        let sum = weights.reduce(0, +)
        return zip(ids, weights).map { SelectorStep(id: $0, dwell: totalDuration * $1 / sum) }
    }

    /// Reduce Motion: no travel, just the winner.
    public static func reduced(winnerID: TouchID) -> [SelectorStep] {
        [SelectorStep(id: winnerID, dwell: 0.3)]
    }
}
