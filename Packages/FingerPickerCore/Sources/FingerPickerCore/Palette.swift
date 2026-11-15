import Foundation

public enum ColorMood: String, CaseIterable, Sendable {
    case vivid = "Vivid"
    case cool = "Cool"
    case warm = "Warm"
}

/// Controlled palette of vivid, mutually distinguishable hues (sRGB 0...1).
/// Order matters: colors are handed out lowest-free-index first, so the first
/// few fingers always get the most distinct hues.
public enum Palette {
    public struct RGB: Equatable, Sendable { public let r, g, b: Double }

    public static let colors: [RGB] = [
        RGB(r: 1.00, g: 0.27, b: 0.35), // coral red
        RGB(r: 0.72, g: 0.40, b: 1.00), // violet
        RGB(r: 1.00, g: 0.80, b: 0.15), // amber yellow
        RGB(r: 1.00, g: 0.40, b: 0.80), // pink
        RGB(r: 0.20, g: 0.78, b: 1.00), // sky cyan
        RGB(r: 0.15, g: 0.90, b: 0.75), // aqua mint
        RGB(r: 1.00, g: 0.52, b: 0.12), // orange
        RGB(r: 0.40, g: 0.90, b: 0.40), // lime green
        RGB(r: 0.85, g: 1.00, b: 0.30), // chartreuse
        RGB(r: 0.40, g: 0.50, b: 1.00), // indigo blue
    ]

    private static let coolColors: [RGB] = [
        RGB(r: 0.18, g: 0.78, b: 1.00), RGB(r: 0.48, g: 0.42, b: 1.00),
        RGB(r: 0.15, g: 0.88, b: 0.78), RGB(r: 0.34, g: 0.64, b: 0.98),
        RGB(r: 0.68, g: 0.48, b: 0.96), RGB(r: 0.20, g: 0.72, b: 0.82),
        RGB(r: 0.50, g: 0.86, b: 0.58), RGB(r: 0.36, g: 0.52, b: 0.92),
        RGB(r: 0.72, g: 0.66, b: 1.00), RGB(r: 0.30, g: 0.88, b: 0.96)
    ]

    private static let warmColors: [RGB] = [
        RGB(r: 1.00, g: 0.30, b: 0.38), RGB(r: 1.00, g: 0.56, b: 0.18),
        RGB(r: 1.00, g: 0.78, b: 0.20), RGB(r: 0.96, g: 0.36, b: 0.58),
        RGB(r: 0.84, g: 0.42, b: 0.30), RGB(r: 0.98, g: 0.62, b: 0.38),
        RGB(r: 0.82, g: 0.72, b: 0.28), RGB(r: 0.92, g: 0.42, b: 0.72),
        RGB(r: 0.72, g: 0.48, b: 0.28), RGB(r: 1.00, g: 0.68, b: 0.52)
    ]

    public static func colors(for mood: ColorMood) -> [RGB] {
        switch mood {
        case .vivid: return colors
        case .cool: return coolColors
        case .warm: return warmColors
        }
    }

    public static var count: Int { colors.count }

    /// Assign the least-used color so repeats stay balanced beyond ten participants.
    public static func nextFreeIndex(used: [Int]) -> Int {
        let counts = (0..<count).map { index in used.filter { $0 == index }.count }
        return counts.indices.min { counts[$0] < counts[$1] } ?? 0
    }

    /// Relative luminance (WCAG) of a palette color, for choosing legible overlay text.
    public static func luminance(_ c: RGB) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }
    /// True when dark text reads better than white on this color.
    /// Black and white have equal WCAG contrast at luminance ~0.179, so that is the crossover.
    public static func prefersDarkText(on c: RGB) -> Bool { luminance(c) > 0.179 }
}
