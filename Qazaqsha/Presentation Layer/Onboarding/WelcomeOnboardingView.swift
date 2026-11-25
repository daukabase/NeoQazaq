//
//  WelcomeOnboardingView.swift
//  Qazaqsha
//
//  Step 1: Batyrma introduces itself in the way its users write: Kazakh and Russian mixed,
//  typed without Kazakh letters and corrected live. Ends with one question (how do you
//  usually write?) that replaces the "Get started" tap, so it costs no extra step; the answer
//  is echoed back and sent to analytics (onboarding_writing_style).
//

import SwiftUI
import QazaqFoundation

struct WelcomeOnboardingView: View {
    enum WritingStyle: String, CaseIterable, Identifiable {
        case kazakh, russian, mixed

        var id: String { rawValue }

        var label: String {
            switch self {
            case .kazakh: return "Қазақша"
            case .russian: return "По-русски"
            case .mixed: return "Аралас / вперемешку"
            }
        }

        var reply: String {
            switch self {
            case .kazakh: return "Керемет! Ә, ғ, қ, ң — бәрін өзім қоямын."
            case .russian: return "Понял 👌 Русский не трогаю, ал қазақша сөздерді өзім түзеймін."
            case .mixed: return "Мен де! 😄 Қай тілде жазғаныңды өзім түсінемін."
            }
        }
    }

    static let introLines = [
        "Сәлем, қалайсың? 👋",
        "Менің атым Batyrma.",
        "Менімен қазақша да, и на русском можешь писать.",
        "Қалай ыңғайлы, солай жаза бер — таза қазақша жазуға көмектесемін.",
        "Привычкаларыңды бұзбай 😉",
    ]
    static let question = "Сен әдетте қалай жазасың?"
    static let writingStyleKey = "onboardingWritingStyle"

    /// Called when the conversation is over and the main button can appear.
    var onReady: () -> Void = {}

    @State private var lines = Self.introLines
    @State private var showsAnswers = false
    @State private var answer: WritingStyle?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TypedLinesView(lines: lines, showsSkipHint: true, onFinished: linesFinished)

                if showsAnswers {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(WritingStyle.allCases) { style in
                            Button(style.label) { choose(style) }
                                .buttonStyle(AnswerButtonStyle())
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if answer != nil {
                    Text("common_privacy_policy_content")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.45))
                        .tint(OnboardingTheme.accent)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
    }

    private func linesFinished() {
        if !lines.contains(Self.question) {
            lines.append(Self.question)
        } else if answer == nil {
            withAnimation(.easeOut) { showsAnswers = true }
        } else {
            onReady()
        }
    }

    private func choose(_ style: WritingStyle) {
        guard answer == nil else { return }
        withAnimation(.easeOut) {
            answer = style
            showsAnswers = false
        }
        lines.append(style.reply)
        UserDefaults.standard.set(style.rawValue, forKey: Self.writingStyleKey)
        AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(
            name: "onboarding_writing_style",
            params: ["style": style.rawValue]
        ))
    }
}

/// An answer the user can tap: outlined pill, left-aligned like a chat reply.
private struct AnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(height: 50)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.25 : 0.1)))
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackground()
            WelcomeOnboardingView()
        }
        .preferredColorScheme(.dark)
    }
}
