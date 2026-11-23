import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Bright "daylight" palette — airy surfaces, apricot accent, deep teal for home/live.
enum Theme {
    static let bg = Color(hex: 0xF3F5F9)
    static let surface = Color(hex: 0xFFFFFF)
    static let surface2 = Color(hex: 0xF7F8FB)
    static let surface3 = Color(hex: 0xEEF1F6)
    static let chip = Color(hex: 0xEAF0F7)
    static let userBubble = Color(hex: 0xE2ECF8)
    static let border = Color(hex: 0xDCE2EB)
    static let borderSoft = Color(hex: 0xE7EBF1)
    static let handle = Color(hex: 0xC9D1DD)

    static let text = Color(hex: 0x1B2331)
    static let text2 = Color(hex: 0x2B3444)
    static let text3 = Color(hex: 0x3F4959)
    static let soft = Color(hex: 0x4F5A6B)
    static let muted = Color(hex: 0x636D7E)
    static let faint = Color(hex: 0x7C8696)
    static let disabled = Color(hex: 0xA9B1BD)

    /// Fill colour for buttons, pins and highlights.
    static let accent = Color(hex: 0xF59E4C)
    static let accentLight = Color(hex: 0xFBC48F)
    /// Darker apricot for accent-coloured text on light surfaces (meets 4.5:1).
    static let accentInk = Color(hex: 0xB2541A)
    /// Route line and destination pin on the globe.
    static let route = Color(hex: 0xE57F2E)
    static let onAccent = Color(hex: 0x3A1C05)
    static let sage = Color(hex: 0x1C7D69)
    static let sky = Color(hex: 0x2F74B5)
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
