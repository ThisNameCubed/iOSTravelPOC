import SwiftUI

// MARK: - Layout

/// Wraps children onto new lines, like CSS flex-wrap.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Small pieces

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.muted)
            .padding(.horizontal, 4)
            .padding(.top, 24)
            .padding(.bottom, 10)
    }
}

enum ChipStyle { case plain, selected, red, agent }

struct Chip: View {
    let text: String
    var style: ChipStyle = .plain
    var height: CGFloat = 36

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 14)
            .frame(height: height)
            .background(background, in: Capsule())
            .overlay(Capsule().stroke(style == .plain ? Theme.line : .clear))
    }

    private var foreground: Color {
        switch style {
        case .plain: return Theme.ink
        case .selected, .red: return .white
        case .agent: return Theme.red
        }
    }

    private var background: Color {
        switch style {
        case .plain: return Theme.surface
        case .selected: return Theme.ink
        case .red: return Theme.red
        case .agent: return Theme.redTint
        }
    }
}

enum TagStyle { case gold, green, red, grey }

struct Tag: View {
    let text: String
    var style: TagStyle = .grey

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(bg, in: Capsule())
    }

    private var fg: Color {
        switch style {
        case .gold: return Theme.goldDark
        case .green: return Theme.green
        case .red: return .white
        case .grey: return Theme.ink
        }
    }

    private var bg: Color {
        switch style {
        case .gold: return Theme.goldTint
        case .green: return Theme.greenTint
        case .red: return Theme.red
        case .grey: return Theme.bg
        }
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String?
    var height: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                if let icon { Image(systemName: icon) }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Theme.red, in: Capsule())
        }
        .buttonStyle(PressStyle())
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    var radius: CGFloat = 20
    var stroke: Color = Theme.line
    var lineWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(stroke, lineWidth: lineWidth))
    }
}

extension View {
    func card(radius: CGFloat = 20, stroke: Color = Theme.line, lineWidth: CGFloat = 1) -> some View {
        modifier(CardBackground(radius: radius, stroke: stroke, lineWidth: lineWidth))
    }
}

/// Horizontal flight line with an optional stop marker and a caption under it.
struct RouteLine: View {
    let caption: String
    var stopColor: Color? = Theme.red

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Capsule().fill(Theme.line).frame(height: 2)
                if let stopColor {
                    Circle()
                        .fill(.white)
                        .overlay(Circle().stroke(stopColor, lineWidth: 2))
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "airplane")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 6)
                        .background(Theme.surface)
                }
            }
            .frame(height: 14)
            Text(caption)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(stopColor ?? Theme.muted)
                .lineLimit(1)
        }
    }
}

// MARK: - Composer (the Atlas chat bar)

struct Composer: View {
    @Binding var text: String
    var placeholder: String
    var focus: FocusState<Bool>.Binding
    let onCalendar: () -> Void
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            AgentOrb(size: 24)
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .focused(focus)
                .submitLabel(.send)
                .onSubmit(onSend)
            Button(action: onCalendar) {
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 40, height: 40)
                    .background(Theme.bg, in: Circle())
            }
            .accessibilityLabel("Open calendar")
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.red, in: Circle())
            }
            .accessibilityLabel("Send")
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.line))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        .padding(.horizontal, 16)
    }
}

struct TypingIndicator: View {
    @State private var phase = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Theme.soft)
                    .frame(width: 7, height: 7)
                    .opacity(phase ? 0.3 : 1)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: phase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .card(radius: 18)
        .onAppear { phase = true }
    }
}
