import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension Color {
    /// A colour that follows the current appearance (Light / Dark).
    init(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkAlpha) : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

/// Light mode: bright "daylight". Dark mode: soft "dusk". Every colour adapts automatically.
enum Theme {
    static let bg = Color(light: 0xF3F5F9, dark: 0x121925)
    static let surface = Color(light: 0xFFFFFF, dark: 0x19212F)
    static let surface2 = Color(light: 0xF7F8FB, dark: 0x1D2636)
    static let surface3 = Color(light: 0xEEF1F6, dark: 0x212B3C)
    static let chip = Color(light: 0xEAF0F7, dark: 0x253043)
    static let userBubble = Color(light: 0xE2ECF8, dark: 0x2A3650)
    static let border = Color(light: 0xDCE2EB, dark: 0x2E394C)
    static let borderSoft = Color(light: 0xE7EBF1, dark: 0x2A3446)
    static let handle = Color(light: 0xC9D1DD, dark: 0x3A4660)

    static let text = Color(light: 0x1B2331, dark: 0xE3E7EE)
    static let text2 = Color(light: 0x2B3444, dark: 0xD3D9E2)
    static let text3 = Color(light: 0x3F4959, dark: 0xC3CAD5)
    static let soft = Color(light: 0x4F5A6B, dark: 0xAAB2BF)
    static let muted = Color(light: 0x636D7E, dark: 0x9AA3B1)
    static let faint = Color(light: 0x7C8696, dark: 0x8C95A4)
    static let disabled = Color(light: 0xA9B1BD, dark: 0x6E7889)

    /// Fill colour for buttons, pins and highlights.
    static let accent = Color(light: 0xF59E4C, dark: 0xE9B676)
    static let accentLight = Color(light: 0xFBC48F, dark: 0xF2CE9E)
    /// Accent-coloured text (meets 4.5:1 on its surface in both modes).
    static let accentInk = Color(light: 0xB2541A, dark: 0xE9B676)
    /// Route line and destination pin on the globe.
    static let route = Color(light: 0xE57F2E, dark: 0xE9B676)
    static let onAccent = Color(light: 0x3A1C05, dark: 0x2B1F10)
    static let sage = Color(light: 0x1C7D69, dark: 0x86CFC0)
    static let sky = Color(light: 0x2F74B5, dark: 0x94BCE3)
    static let shadow = Color(light: 0x1B2331, dark: 0x000000, lightAlpha: 0.10, darkAlpha: 0.40)

    /// Primary action colour: purple → red → yellow. Every main button uses this, in both modes.
    static let primaryGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: Color(hex: 0x6A4CE0), location: 0),
            .init(color: Color(hex: 0xD6336C), location: 0.55),
            .init(color: Color(hex: 0xF4B23A), location: 1)
        ]),
        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let onPrimary = Color.white
    static let primaryGlow = Color(hex: 0xD6336C).opacity(0.30)
}

/// In-app appearance override (stored with @AppStorage("appearance")).
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Match iPhone"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Font {
    /// Wide display face for headings — SF Pro Expanded.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight).width(.expanded)
    }
}

/// Selectable option card (flights, stays, cars).
struct OptionCardStyle: ViewModifier {
    let selected: Bool
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(selected ? Theme.accent.opacity(0.07) : Theme.surface2))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(selected ? Theme.accent : Theme.border, lineWidth: 1.5))
    }
}

extension View {
    func optionCard(selected: Bool) -> some View { modifier(OptionCardStyle(selected: selected)) }

    func glassPill() -> some View {
        self
            .background(Capsule().fill(Theme.surface.opacity(0.78)))
            .background(Capsule().fill(.ultraThinMaterial).opacity(0.5))
            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
    }
}

/// Round icon button used in the top bar.
struct CircleIcon: View {
    let systemName: String
    var color: Color = Theme.text
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .background(Circle().fill(Theme.surface.opacity(0.78)))
            .overlay(Circle().strokeBorder(Theme.border, lineWidth: 1))
    }
}

/// The agent's avatar: an apricot orb with an orbit ring.
struct AgentAvatar: View {
    var size: CGFloat = 40
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Theme.accentLight, Theme.accent, Color(hex: 0xC08A4E)],
                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.7))
            Circle().stroke(Theme.onAccent, lineWidth: size * 0.05).frame(width: size * 0.26, height: size * 0.26)
            Ellipse().stroke(Theme.onAccent, lineWidth: size * 0.05)
                .frame(width: size * 0.72, height: size * 0.32)
                .rotationEffect(.degrees(-25))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
