//
//  TryItOnboardingView.swift
//  Qazaqsha
//
//  Step 3: the success moment. Batyrma asks the user to type a word without Kazakh letters;
//  when the keyboard restores one, Batyrma celebrates (onboarding_try_it_success). The main
//  button appears as soon as the request is typed, so nobody gets stuck here.
//

import SwiftUI
import QazaqFoundation

struct TryItOnboardingView: View {
    static let introLines = [
        "Енді өзің жазып көр ✍️",
        "Мысалы, «калайсын» деп жаз — ә, қ, ң-сыз.",
    ]
    static let successLine = "Міне! Сен жаздың — мен түзедім ✨"
    private static let kazakhLetters = Set("әғқңөұүһіӘҒҚҢӨҰҮҺІ")

    var onReady: () -> Void = {}

    @State private var lines = Self.introLines
    @State private var text = ""
    @State private var didSucceed = false
    @State private var showSwitchGuide = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TypedLinesView(lines: lines) {
                    onReady()
                    if !didSucceed { isFocused = true }
                }

                TextField("", text: textBinding, prompt: Text("Type here").foregroundColor(.white.opacity(0.35)))
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .tint(OnboardingTheme.accent)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.1)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(didSucceed ? OnboardingTheme.accent : Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .focused($isFocused)

                Button(action: { showSwitchGuide = true }) {
                    Label("onboarding_try_switch_hint", systemImage: "globe")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showSwitchGuide) {
            KeyboardSelectionGuideView()
        }
    }

    /// The first Kazakh-only letter in the field means the keyboard restored it
    /// (the user was asked to type without them).
    private var textBinding: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = newValue
                if !didSucceed, newValue.contains(where: Self.kazakhLetters.contains) {
                    didSucceed = true
                    lines.append(Self.successLine)
                    AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(name: "onboarding_try_it_success"))
                }
            }
        )
    }
}

struct TryItOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackground()
            TryItOnboardingView()
        }
        .preferredColorScheme(.dark)
    }
}
