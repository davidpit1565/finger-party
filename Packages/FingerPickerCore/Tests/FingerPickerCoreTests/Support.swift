@testable import FingerPickerCore

/// Deterministic picker: returns scripted indices (wrapping), clamped into range.
struct ScriptedPicker: IndexPicker {
    var script: [Int]
    var i = 0
    init(_ script: [Int]) { self.script = script }
    mutating func pick(upperBound: Int) -> Int {
        defer { i += 1 }
        return script[i % script.count] % upperBound
    }
}

/// SplitMix64-backed picker for reproducible statistical tests.
struct SeededPicker: IndexPicker {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func pick(upperBound: Int) -> Int {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z ^= z >> 31
        return Int(z % UInt64(upperBound))
    }
}

func P(_ id: Int, _ x: Double = 0.5, _ y: Double = 0.5, color: Int? = nil) -> Participant {
    Participant(id: TouchID(id), point: NormalizedPoint(x: x, y: y), colorIndex: color ?? id % Palette.count)
}
let pt = NormalizedPoint(x: 0.5, y: 0.5)
