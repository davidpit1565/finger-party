import Foundation

public enum RevealGeometry {
    /// Smallest circle radius centered at `origin` (view coordinates) that covers the whole rect.
    /// Used so the color takeover always reaches every corner without a seam.
    public static func coverRadius(origin: (x: Double, y: Double), width: Double, height: Double) -> Double {
        let corners = [(0.0, 0.0), (width, 0.0), (0.0, height), (width, height)]
        return corners.map { hypot($0.0 - origin.x, $0.1 - origin.y) }.max() ?? 0
    }

    /// Maps a normalized point into the given bounds.
    public static func denormalize(_ p: NormalizedPoint, width: Double, height: Double) -> (x: Double, y: Double) {
        (p.x * width, p.y * height)
    }

    public static func normalize(x: Double, y: Double, width: Double, height: Double) -> NormalizedPoint {
        guard width > 0, height > 0 else { return NormalizedPoint(x: 0.5, y: 0.5) }
        return NormalizedPoint(x: min(max(x / width, 0), 1), y: min(max(y / height, 0), 1))
    }
}
