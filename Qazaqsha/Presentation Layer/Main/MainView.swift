//
//  MainView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 14.04.2024.
//
//  Home. Same dark look and voice as the onboarding. Answers, top to bottom: is my keyboard
//  working (status card, with the setup video while it isn't), can I try it (practice field),
//  what else can I do (skins, stats, privacy), then the rest (settings, help, sponsors).
//

import SwiftUI
import QazaqFoundation
import StoreKit

final class MainViewModel: ObservableObject {
    @Published
    var keyboardSelectionShowing = false
}

struct MainView: View {
    @ObservedObject
    var viewModel: MainViewModel
    @ObservedObject
    private var skins = SkinStore.shared
    @StateObject
    private var keyboardSetupModel = NewKeyboardSetupViewModel()

    @State private var feedbackType: FeedbackService.FeedbackType?
    @State private var isKeyboardEnabled = GlobalConstants.isKeyboardExtensionEnabled
    @State private var greeting: [String] = []
    @State private var practiceText = ""
    @State private var stats = TypingStats.snapshot()
    @State private var isFullAccessConfirmed = Self.fullAccessConfirmed
    @State private var showsManualSteps = false
    @State private var showsShareCard = false
    @FocusState private var isPracticeFocused: Bool
    @Environment(\.openURL) private var openURL

    private static let kazakhLetters = Set("әғқңөұүһіӘҒҚҢӨҰҮҺІ")

    var body: some View {
        #if DEBUG
        // QA: HOME_SCREEN=sponsor opens the pitch page; HOME_SCREEN=bottom scrolls to the end.
        if ProcessInfo.processInfo.environment["HOME_SCREEN"] == "sponsor" {
            NavigationView { SponsorPitchView() }
        } else {
            home
        }
        #else
        home
        #endif
    }

    private var home: some View {
        NavigationView {
            ZStack {
                OnboardingBackground()
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        statusCard
                        if isKeyboardEnabled { practiceCard }
                        skinsSection
                        statsCard
                        privacyCard
                        sponsorCard
                        moreList
                        footer.id("footer")
                    }
                    .padding(.vertical, 16)
                }
                #if DEBUG
                .onAppear {
                    let env = ProcessInfo.processInfo.environment
                    if env["HOME_SCREEN"] == "bottom" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { proxy.scrollTo("footer", anchor: .bottom) }
                    }
                    // QA (App Store screenshots): KEYBOARD_SKIN=<id> picks a free style;
                    // HOME_PRACTICE=<text> opens the keyboard on the practice field and fills it in,
                    // so the real keyboard shows its suggestions for that text.
                    if let id = env["KEYBOARD_SKIN"], let skin = KeyboardSkin.all.first(where: { $0.id == id }) {
                        skins.select(skin)
                    }
                    if let text = env["HOME_PRACTICE"] {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isPracticeFocused = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { practiceText = text }
                    }
                }
                #endif
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.keyboardSelectionShowing) { KeyboardSelectionGuideView() }
        .sheet(isPresented: $showsManualSteps) { ManualKeyboardSetupView() }
        .sheet(item: $feedbackType) { FeedbackView(type: $0) }
        .sheet(isPresented: $showsShareCard) { StatsShareSheet(content: StatsShareContent(stats: stats)) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
        .onAppear {
            if greeting.isEmpty {
                greeting = isKeyboardEnabled
                    ? ["Сәлем! 👋", "Бүгін не жазамыз?"]
                    : ["Сәлем! 👋", "Мені әлі пернетақтаға қоспадың 🙂"]
            }
            refresh()
            #if DEBUG
            // Screenshot runs: no rating prompt over the keyboard.
            if ProcessInfo.processInfo.environment["HOME_PRACTICE"] != nil { return }
            #endif
            DispatchQueue.main.async { AppReviewService.shared.requestReviewIfNeeded() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            BatyrmaOrb(size: 48)
                .offset(x: -8, y: -8)
            TypedLinesView(lines: greeting, dimsEarlierLines: false)
                .padding(.top, 6)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var statusCard: some View {
        if isKeyboardEnabled {
            Button(action: { viewModel.keyboardSelectionShowing = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("home_keyboard_on")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("onboarding_try_switch_hint")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.55))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                }
                .card()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        } else {
            VStack(spacing: 16) {
                SetupVideoView()
                    .frame(maxHeight: 320)
                Button(action: openSettings) { Text("setup_open_settings") }
                    .buttonStyle(OnboardingPillButtonStyle())
                Button("Show manual setup steps") { showsManualSteps = true }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.55))
            }
            .card()
            .padding(.horizontal, 24)
        }
    }

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("home_try_title")
            TextField("", text: $practiceText, prompt: Text("Type here").foregroundColor(.white.opacity(0.35)))
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .tint(OnboardingTheme.accent)
                .focused($isPracticeFocused)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.08)))
            if practiceText.contains(where: Self.kazakhLetters.contains) {
                Label("onboarding_try_success", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(OnboardingTheme.accent)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
        .animation(.easeOut, value: practiceText.contains(where: Self.kazakhLetters.contains))
    }

    private var skinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("home_skins_title")
                .padding(.horizontal, 24)
            SkinPickerView(store: skins)
        }
    }

    @ViewBuilder
    private var statsCard: some View {
        if !stats.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: stats.monthLetters.formatted())
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(OnboardingTheme.accent)
                Text("home_stats_letters")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("home_stats_words\(stats.totalWords)")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.55))
                Button(action: { showsShareCard = true }) {
                    Label("home_stats_share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
            .padding(.horizontal, 24)
        } else if isKeyboardEnabled && !isFullAccessConfirmed {
            Label("home_stats_full_access", systemImage: "chart.bar.fill")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.55))
                .padding(.horizontal, 24)
        }
    }

    private var privacyCard: some View {
        NavigationLink(destination: PrivacyPolicyView()) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundColor(OnboardingTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("home_privacy_title")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("privacy_point_text")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.35))
            }
            .card()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    /// "Supported by" slot. No sponsor yet: invite companies to the pitch page.
    private var sponsorCard: some View {
        NavigationLink(destination: SponsorPitchView()) {
            HStack(spacing: 12) {
                Text(verbatim: "📣")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text("home_sponsor_title")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("home_sponsor_body")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.35))
            }
            .card(stroke: OnboardingTheme.gold.opacity(0.35))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private var moreList: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("home_more")
            VStack(spacing: 0) {
                NavigationLink(destination: SettingsView(viewModel: SettingsViewModel())) {
                    row("gearshape.fill", Text("settings"))
                }
                divider
                NavigationLink(destination: FAQView(viewModel: FAQViewModel())) {
                    row("questionmark.circle.fill", Text("FAQ"))
                }
                divider
                Button(action: { feedbackType = .question }) {
                    row("bubble.left.fill", Text(FeedbackService.FeedbackType.question.title))
                }
                divider
                Button(action: { feedbackType = .collaboration }) {
                    row("hands.sparkles.fill", Text(FeedbackService.FeedbackType.collaboration.title))
                }
                divider
                NavigationLink(destination: PrivacyPolicyView()) {
                    row("hand.raised.fill", Text("Privacy Policy"))
                }
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.07)))
        }
        .padding(.horizontal, 24)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("keyboard_app\(Self.releaseNumber)")
            Text("designed_by\(Self.designer)")
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.45))
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }

    // MARK: - Pieces

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.title3.weight(.bold))
            .foregroundColor(.white)
    }

    private func row(_ systemImage: String, _ title: Text) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .foregroundColor(OnboardingTheme.accent)
                .frame(width: 24)
            title
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .contentShape(Rectangle())
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 54)
    }

    // MARK: - Actions

    static let designer = "Daulet Almagambetov"

    /// "1.1.3 (2)": marketing version and build number.
    static var releaseNumber: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return build.map { "\(GlobalConstants.appVersion) (\($0))" } ?? GlobalConstants.appVersion
    }

    private static var fullAccessConfirmed: Bool {
        UserDefaults.localAppGroup.object(forKey: UserDefaults.keyboardFullAccessLastSeenKey) != nil
    }

    private func refresh() {
        let enabled = GlobalConstants.isKeyboardExtensionEnabled
        if enabled && !isKeyboardEnabled && !greeting.isEmpty {
            greeting.append("Тамаша, мен қосылдым! 🎉")
        }
        isKeyboardEnabled = enabled
        keyboardSetupModel.isKeyboardAdded = enabled
        stats = TypingStats.snapshot()
        isFullAccessConfirmed = Self.fullAccessConfirmed
    }

    private func openSettings() {
        keyboardSetupModel.openSettingsTapped()
        openURL(URL(string: UIApplication.openSettingsURLString)!)
    }

}

extension View {
    /// Rounded translucent card used across the home screen.
    func card(stroke: Color = Color.white.opacity(0.1)) -> some View {
        padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(stroke, lineWidth: 1))
    }
}

struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: MainViewModel())
    }
}
