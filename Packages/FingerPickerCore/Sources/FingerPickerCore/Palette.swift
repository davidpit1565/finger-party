import Foundation

/// Controlled palette of vivid, mutually distinguishable hues (sRGB 0...1).
/// Order matters: colors are handed out lowest-free-index first, so the first
/// few fingers always get the most distinct hues.
public enum Palette {
    public struct RGB: Equatable, Sendable { public let r, g, b: Double }

    public static let colors: [RGB] = [
        RGB(r: 1.00, g: 0.27, b: 0.35), // coral red
        RGB(r: 0.20, g: 0.78, b: 1.00), // sky cyan
        RGB(r: 1.00, g: 0.80, b: 0.15), // amber yellow
        RGB(r: 1.00, g: 0.52, b: 0.12), // orange
        RGB(r: 0.72, g: 0.40, b: 1.00), // violet
        RGB(r: 0.40, g: 0.90, b: 0.40), // lime green
        RGB(r: 0.15, g: 0.90, b: 0.75), // aqua mint
        RGB(r: 1.00, g: 0.40, b: 0.80), // pink
        RGB(r: 0.40, g: 0.50, b: 1.00), // indigo blue
        RGB(r: 0.85, g: 1.00, b: 0.30), // chartreuse
    ]

    public static var count: Int { colors.count }

    /// Lowest palette index not currently in use; wraps if more fingers than colors.
    public static func nextFreeIndex(used: Set<Int>) -> Int {
        for i in 0..<count where !used.contains(i) { return i }
        // All in use: reuse starting from the least-used slot (wrap by count of used).
        return used.count % count
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
