import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var state
    @FocusState private var focused: Bool
    @State private var draft = ""

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(state.messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                    if state.isTyping {
                        TypingIndicator().padding(.leading, 32)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: state.messages.count) { scrollDown(proxy) }
            .onChange(of: state.isTyping) { scrollDown(proxy) }
            .onChange(of: state.stepsDone) { scrollDown(proxy) }
        }
        .background(Theme.bg)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if !state.quickReplies.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(state.quickReplies, id: \.self) { reply in
                                Button { state.tapQuickReply(reply) } label: { Chip(text: reply) }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                Composer(text: $draft, placeholder: "Add a constraint…", focus: $focused,
                         onCalendar: { state.openCalendar(.chat) },
                         onSend: send)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Theme.bg.opacity(0.96))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    AgentOrb(size: 22)
                    Text("New trip").font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .onChange(of: state.focusRequest) {
            if state.calendarSource != .home { focused = true }
        }
    }

    private func send() {
        let text = draft
        draft = ""
        state.send(text)
    }

    private func scrollDown(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom", anchor: .bottom) }
    }
}

struct MessageRow: View {
    @Environment(AppState.self) private var state
    let message: ChatMessage

    var body: some View {
        switch message.kind {
        case .user:
            HStack {
                Spacer(minLength: 60)
                Text(verbatim: message.text)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.red, in: UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22,
                                                                     bottomTrailingRadius: 6, topTrailingRadius: 22,
                                                                     style: .continuous))
            }
        case .agent:
            HStack(alignment: .top, spacing: 10) {
                AgentOrb(size: 22)
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStringKey(message.text))
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.ink)
                    if !message.actions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(message.actions, id: \.self) { action in
                                Button { state.perform(action) } label: {
                                    Chip(text: action.label, style: action.isPrimary ? .red : .plain, height: 34)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Theme.surface, in: UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20,
                                                                      bottomTrailingRadius: 20, topTrailingRadius: 20,
                                                                      style: .continuous))
                .overlay(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20,
                                                bottomTrailingRadius: 20, topTrailingRadius: 20,
                                                style: .continuous).stroke(Theme.line))
                Spacer(minLength: 16)
            }
        case .steps:
            StepsCard()
        case .understood:
            VStack(alignment: .leading, spacing: 8) {
                Text("I understood")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .padding(.leading, 4)
                FlowLayout(spacing: 8) {
                    ForEach(state.understood, id: \.self) { item in
                        Chip(text: item, style: .agent, height: 30)
                    }
                }
            }
        }
    }
}

struct StepsCard: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(state.stepLabels.enumerated()), id: \.offset) { index, label in
                let done = index < state.stepsDone
                let live = index == state.stepsDone
                HStack(spacing: 12) {
                    ZStack {
                        if done {
                            Circle().fill(Theme.ink)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white)
                        } else if live {
                            ProgressView().controlSize(.small).tint(Theme.red)
                        } else {
                            Circle().stroke(Theme.line, lineWidth: 1.5)
                        }
                    }
                    .frame(width: 20, height: 20)
                    Text(label)
                        .font(.system(size: 14, weight: done || live ? .medium : .regular))
                        .foregroundStyle(done ? Theme.ink : live ? Theme.red : Theme.soft)
                }
                .padding(.vertical, 9)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
