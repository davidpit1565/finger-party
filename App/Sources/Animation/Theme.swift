// Theme.swift - shared visual tokens for Finger Picker.
//
// DESIGN DECISIONS (full notes: DESIGN/DESIGN-NOTES.md)
// - Background #0B0B10: near-black with a hint of blue so saturated hues pop and OLED
//   stays calm; one solid color, no gradient behind touch markers (spec section 7).
// - Marker colors come only from FingerPickerCore.Palette (single source of truth), sRGB.
// - Overlay text flips between near-black and white via Palette.prefersDarkText so it is
//   legible on every possible winner color (yellow / chartreuse need dark text).
// - Durations: marker appear spring ~0.35s; selector emphasis change 0.12s ease-out (crisp
//   hopping); winner wave 0.9s ease-out; Reduce Motion crossfade 0.35s; idle pulse 1.6s.
// - No blur stacks, no particles: glows are radial gradients + layered strokes.

import SwiftUI
import FingerPickerCore

enum Theme {
    /// Near-black deep charcoal play background (#0B0B10).
    static let background = Color(.sRGB, red: 11.0 / 255.0, green: 11.0 / 255.0, blue: 16.0 / 255.0, opacity: 1)

    /// Palette color for a color index (wraps; negative-safe).
    static func color(_ colorIndex: Int) -> Color {
        let rgb = paletteRGB(colorIndex)
        return Color(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1)
    }

    /// Legible text color to place over the marker/winner color at `onColorIndex`.
    static func overlayText(onColorIndex: Int) -> Color {
        if Palette.prefersDarkText(on: paletteRGB(onColorIndex)) {
            return Color(.sRGB, red: 0.04, green: 0.04, blue: 0.07, opacity: 0.92)
        }
        return Color.white
    }

    /// Muted text for hints on the dark background.
    static var secondaryText: Color {
        Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.55)
    }

    private static func paletteRGB(_ index: Int) -> Palette.RGB {
        let n = Palette.colors.count
        let i = ((index % n) + n) % n
        return Palette.colors[i]
    }
}
