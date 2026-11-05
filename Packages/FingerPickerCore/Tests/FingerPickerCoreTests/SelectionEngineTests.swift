import XCTest
@testable import FingerPickerCore

final class SelectionEngineTests: XCTestCase {
    func testRejectsZeroAndOneParticipant() {
        var p = ScriptedPicker([0])
        XCTAssertThrowsError(try SelectionEngine.selectWinner(from: [], using: &p)) {
            XCTAssertEqual($0 as? SelectionError, .notEnoughParticipants)
        }
        XCTAssertThrowsError(try SelectionEngine.selectWinner(from: [P(1)], using: &p))
    }

    func testRejectsDuplicateIDs() {
        var p = ScriptedPicker([0])
        XCTAssertThrowsError(try SelectionEngine.selectWinner(from: [P(1), P(1)], using: &p)) {
            XCTAssertEqual($0 as? SelectionError, .duplicateParticipants)
        }
    }

    func testEveryIndexIsReachable() throws {
        let ps = (1...5).map { P($0) }
        for idx in 0..<5 {
            var p = ScriptedPicker([idx])
            XCTAssertEqual(try SelectionEngine.selectWinner(from: ps, using: &p), ps[idx].id)
        }
    }

    /// Color, coordinate and touch order must not influence which index maps to which winner.
    func testSelectionIndependentOfColorAndPosition() throws {
        let a = [P(1, 0.1, 0.1, color: 0), P(2, 0.9, 0.9, color: 1), P(3, 0.5, 0.2, color: 2)]
        let b = [P(1, 0.7, 0.3, color: 5), P(2, 0.2, 0.8, color: 4), P(3, 0.4, 0.4, color: 9)]
        for idx in 0..<3 {
            var p1 = ScriptedPicker([idx]), p2 = ScriptedPicker([idx])
            XCTAssertEqual(try SelectionEngine.selectWinner(from: a, using: &p1),
                           try SelectionEngine.selectWinner(from: b, using: &p2))
        }
    }

    /// Uniformity: 4 participants, 40k seeded draws, each within 5% relative of expected.
    func testSystemStyleUniformDistribution() throws {
        let ps = (1...4).map { P($0) }
        var picker = SeededPicker(seed: 42)
        var counts = [TouchID: Int]()
        let n = 40_000
        for _ in 0..<n { counts[try SelectionEngine.selectWinner(from: ps, using: &picker), default: 0] += 1 }
        for p in ps {
            let c = Double(counts[p.id] ?? 0)
            XCTAssertEqual(c, Double(n) / 4, accuracy: Double(n) / 4 * 0.05, "id \(p.id.rawValue)")
        }
    }

    func testSystemPickerStaysInRange() {
        var p = SystemIndexPicker()
        for _ in 0..<2_000 { let v = p.pick(upperBound: 7); XCTAssertTrue((0..<7).contains(v)) }
    }
}

final class SelectorRouteTests: XCTestCase {
    func testRouteAlwaysEndsOnWinnerForEveryWinnerAndCount() {
        for n in 2...10 {
            let ps = (1...n).map { P($0) }
            for w in ps {
                let route = SelectorRoute.make(participants: ps, winnerID: w.id)
                XCTAssertEqual(route.last?.id, w.id, "n=\(n) winner=\(w.id.rawValue)")
                XCTAssertGreaterThanOrEqual(route.count, 14)
                // Every step is a real participant.
                XCTAssertTrue(route.allSatisfy { s in ps.contains { $0.id == s.id } })
            }
        }
    }

    func testRouteDecelerates() {
        let route = SelectorRoute.make(participants: (1...4).map { P($0) }, winnerID: TouchID(2))
        for (a, b) in zip(route, route.dropFirst()) { XCTAssertLessThanOrEqual(a.dwell, b.dwell) }
        XCTAssertEqual(route.reduce(0) { $0 + $1.dwell }, 2.4, accuracy: 0.001)
    }

    func testRouteIndependentOfInputOrderAndHasNoRandomness() {
        let ps = (1...5).map { P($0) }
        let r1 = SelectorRoute.make(participants: ps, winnerID: TouchID(3))
        let r2 = SelectorRoute.make(participants: ps.reversed(), winnerID: TouchID(3))
        XCTAssertEqual(r1, r2)
    }

    func testReducedMotionRouteIsJustWinner() {
        XCTAssertEqual(SelectorRoute.reduced(winnerID: TouchID(7)).map(\.id), [TouchID(7)])
    }
}

final class GeometryTests: XCTestCase {
    func testCoverRadiusReachesFarthestCorner() {
        let r = RevealGeometry.coverRadius(origin: (x: 10, y: 10), width: 100, height: 200)
        XCTAssertEqual(r, hypot(90, 190), accuracy: 1e-9)
        XCTAssertEqual(RevealGeometry.coverRadius(origin: (x: 50, y: 100), width: 100, height: 200),
                       hypot(50, 100), accuracy: 1e-9)
    }
    func testNormalizeRoundTripAndClamping() {
        let n = RevealGeometry.normalize(x: 150, y: 300, width: 300, height: 600)
        XCTAssertEqual(n, NormalizedPoint(x: 0.5, y: 0.5))
        let d = RevealGeometry.denormalize(n, width: 400, height: 800)
        XCTAssertEqual(d.x, 200); XCTAssertEqual(d.y, 400)
        XCTAssertEqual(RevealGeometry.normalize(x: -5, y: 9999, width: 100, height: 100),
                       NormalizedPoint(x: 0, y: 1))
        XCTAssertEqual(RevealGeometry.normalize(x: 1, y: 1, width: 0, height: 0), NormalizedPoint(x: 0.5, y: 0.5))
    }
}

final class PaletteTests: XCTestCase {
    func testFreeIndexLowestFirstAndWraps() {
        XCTAssertEqual(Palette.nextFreeIndex(used: []), 0)
        XCTAssertEqual(Palette.nextFreeIndex(used: [0, 1]), 2)
        XCTAssertEqual(Palette.nextFreeIndex(used: [1]), 0)
        let all = Set(0..<Palette.count)
        XCTAssertTrue((0..<Palette.count).contains(Palette.nextFreeIndex(used: all)))
    }
    func testPaletteColorsAreDistinctAndInRange() {
        XCTAssertEqual(Set(Palette.colors.map { "\($0.r),\($0.g),\($0.b)" }).count, Palette.count)
        for c in Palette.colors { XCTAssertTrue((0...1).contains(c.r) && (0...1).contains(c.g) && (0...1).contains(c.b)) }
    }

    /// Text chosen by `prefersDarkText` must reach WCAG AA (4.5:1) on every palette color.
    func testOverlayTextContrastMeetsAAOnEveryPaletteColor() {
        let inkLum = Palette.luminance(Palette.RGB(r: 0.04, g: 0.04, b: 0.07))
        for c in Palette.colors {
            let l = Palette.luminance(c)
            let ratio = Palette.prefersDarkText(on: c) ? (l + 0.05) / (inkLum + 0.05) : 1.05 / (l + 0.05)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(c)")
        }
    }
}
