/// Source of uniform random indices. Injectable so tests are deterministic.
public protocol IndexPicker {
    /// Returns an integer in `0..<upperBound`. `upperBound` is always > 0.
    mutating func pick(upperBound: Int) -> Int
}

/// Production picker: Swift's system random source, unbiased range selection.
public struct SystemIndexPicker: IndexPicker {
    private var rng = SystemRandomNumberGenerator()
    public init() {}
    public mutating func pick(upperBound: Int) -> Int { Int.random(in: 0..<upperBound, using: &rng) }
}

public enum SelectionError: Error, Equatable {
    case notEnoughParticipants
    case duplicateParticipants
}

/// Pure winner selection. Knows nothing about animation, colors, positions or touch order:
/// it only draws a uniform index into the frozen participant list.
public enum SelectionEngine {
    public static let minimumParticipants = 2

    public static func selectWinner<P: IndexPicker>(from participants: [Participant],
                                                    using picker: inout P) throws -> TouchID {
        guard participants.count >= minimumParticipants else { throw SelectionError.notEnoughParticipants }
        guard Set(participants.map(\.id)).count == participants.count else { throw SelectionError.duplicateParticipants }
        let index = picker.pick(upperBound: participants.count)
        precondition(participants.indices.contains(index), "picker returned out-of-range index")
        return participants[index].id
    }
}
