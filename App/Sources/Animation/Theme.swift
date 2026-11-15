import SwiftUI
import FingerPickerCore

enum Theme {
    static let background = Color(red: 7/255, green: 10/255, blue: 25/255)
    static let surface = Color(red: 18/255, green: 23/255, blue: 47/255)
    static let cyan = Color(red: 0.25, green: 0.91, blue: 1.0)
    static let coral = Color(red: 1.0, green: 0.31, blue: 0.43)
    static let violet = Color(red: 0.58, green: 0.36, blue: 1.0)
    static let lime = Color(red: 0.76, green: 1.0, blue: 0.30)

    static func color(_ colorIndex: Int, mood: ColorMood = .vivid) -> Color {
        let rgb = paletteRGB(colorIndex, mood: mood)
        return Color(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1)
    }

    static func overlayText(onColorIndex: Int, mood: ColorMood = .vivid) -> Color {
        Palette.prefersDarkText(on: paletteRGB(onColorIndex, mood: mood)) ? ink : .white
    }

    static let ink = Color(.sRGB, red: 0.04, green: 0.04, blue: 0.07, opacity: 0.96)
    static var secondaryText: Color { Color.white.opacity(0.66) }

    private static func paletteRGB(_ index: Int, mood: ColorMood) -> Palette.RGB {
        let colors = Palette.colors(for: mood)
        let n = colors.count
        let i = ((index % n) + n) % n
        return colors[i]
    }
}
