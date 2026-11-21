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

/// Red & gold palette. Swap these values to re-theme the whole app.
enum Theme {
    static let bg = Color(hex: 0xF8F5F0)
    static let surface = Color.white
    static let ink = Color(hex: 0x1F1A17)
    static let muted = Color(hex: 0x6E6560)
    static let soft = Color(hex: 0xA39A94)
    static let line = Color(hex: 0xE9E3DB)
    static let segment = Color(hex: 0xF1E9DF)
    static let red = Color(hex: 0xD71E28)
    static let redDark = Color(hex: 0xA8141C)
    static let redTint = Color(hex: 0xFCEDEC)
    static let gold = Color(hex: 0xFFCD41)
    static let goldDark = Color(hex: 0xB7791F)
    static let goldTint = Color(hex: 0xFFF3D1)
    static let green = Color(hex: 0x13865A)
    static let greenTint = Color(hex: 0xE3F5EC)
    static let mapTop = Color(hex: 0xF6E7D6)
    static let mapDot = Color(hex: 0xE2CDB8)

    static let orbGradient = LinearGradient(
        colors: [Color(hex: 0xE8303A), red, gold],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Four-point sparkle used for everything Atlas (the agent) says or does.
struct Spark: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 16
        let cx = rect.midX, cy = rect.midY
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: cx + x * s, y: cy + y * s) }
        var p = Path()
        p.move(to: pt(0, -8))
        p.addCurve(to: pt(8, 0), control1: pt(1, -2), control2: pt(2, -1))
        p.addCurve(to: pt(0, 8), control1: pt(2, 1), control2: pt(1, 2))
        p.addCurve(to: pt(-8, 0), control1: pt(-1, 2), control2: pt(-2, 1))
        p.addCurve(to: pt(0, -8), control1: pt(-2, -1), control2: pt(-1, -2))
        p.closeSubpath()
        return p
    }
}

struct AgentOrb: View {
    var size: CGFloat = 28

    var body: some View {
        Circle()
            .fill(Theme.orbGradient)
            .frame(width: size, height: size)
            .overlay(Spark().fill(.white).frame(width: size * 0.55, height: size * 0.55))
            .accessibilityHidden(true)
    }
}
