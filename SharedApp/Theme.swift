import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Palette {
    static let ink = Color.adaptive(light: (0.09, 0.13, 0.22), dark: (0.93, 0.95, 0.97))
    static let inkMuted = Color.adaptive(light: (0.29, 0.35, 0.44), dark: (0.72, 0.76, 0.80))
    static let teal = Color(red: 0.18, green: 0.55, blue: 0.56)
    static let tealDeep = Color.adaptive(light: (0.10, 0.37, 0.40), dark: (0.45, 0.78, 0.80))
    static let indigo = Color(red: 0.37, green: 0.42, blue: 0.69)
    static let sage = Color(red: 0.38, green: 0.55, blue: 0.47)
    static let slate = Color(red: 0.42, green: 0.49, blue: 0.56)
    static let amber = Color(red: 0.85, green: 0.56, blue: 0.22)
    static let cream = Color.adaptive(light: (0.97, 0.97, 0.95), dark: (0.07, 0.08, 0.10))
    static let cardLight = Color.adaptive(light: (1, 1, 1), dark: (0.14, 0.16, 0.18))
    static let watchBackground = Color.black
}

extension Color {
    static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        #if os(watchOS)
        Color(red: dark.0, green: dark.1, blue: dark.2)
        #elseif canImport(UIKit)
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
        #else
        Color(red: light.0, green: light.1, blue: light.2)
        #endif
    }
}

extension PaletteAccent {
    var color: Color {
        switch self {
        case .teal: return Palette.teal
        case .indigo: return Palette.indigo
        case .sage: return Palette.sage
        case .slate: return Palette.slate
        case .amber: return Palette.amber
        }
    }
}

extension Font {
    static func countdown(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

enum Motion {
    static func value<V: Equatable>(_ reduceMotion: Bool, _ value: V) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.28)
    }
}

extension AppearancePreference {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
