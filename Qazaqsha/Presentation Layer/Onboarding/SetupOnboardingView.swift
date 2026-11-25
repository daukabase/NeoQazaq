//
//  SetupOnboardingView.swift
//  Qazaqsha
//
//  Step 2: adding the keyboard, the step that lost the most users. Batyrma asks to be added,
//  a looping screen recording shows the exact taps, and Batyrma reacts in the conversation
//  when the user comes back (with help if the keyboard isn't there yet, or a celebration).
//  Events come from NewKeyboardSetupViewModel: setup_settings_opened,
//  setup_returned_without_keyboard, setup_keyboard_detected, setup_postponed.
//

import SwiftUI
import QazaqFoundation

struct SetupOnboardingView: View {
    static let introLines = [
        "Енді мені пернетақтаңа қосайық 👇",
        "Екі қадам ғана: Keyboards → Batyrma.",
    ]
    static let helpLine = "Таппадың ба? Keyboards бөлімін ашып, Batyrma-ны қос."
    static let addedLine = "Тамаша, мен қосылдым! 🎉"

    @ObservedObject var viewModel: NewKeyboardSetupViewModel
    /// Called once the keyboard is added and Batyrma has reacted; shows the main button.
    var onReady: () -> Void = {}

    @Environment(\.openURL) private var openURL
    @State private var lines = Self.introLines
    @State private var showsVideo = false
    @State private var showsManualSteps = false

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TypedLinesView(lines: lines, onFinished: linesFinished)

                    if showsVideo && !viewModel.isKeyboardAdded {
                        SetupVideoView()
                            .frame(maxHeight: 360)
                            .frame(maxWidth: .infinity)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }

            if !viewModel.isKeyboardAdded {
                actions
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.isKeyboardAdded)
        .sheet(isPresented: $showsManualSteps) {
            ManualKeyboardSetupView()
        }
        .onAppear {
            if viewModel.isKeyboardAdded { lines.append(Self.addedLine) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.appBecameActive()
        }
        .onChange(of: viewModel.showReturnHelp) { show in
            if show && !lines.contains(Self.helpLine) { lines.append(Self.helpLine) }
        }
        .onChange(of: viewModel.isKeyboardAdded) { added in
            if added && !lines.contains(Self.addedLine) { lines.append(Self.addedLine) }
        }
    }

    private var actions: some View {
        VStack(spacing: 14) {
            Button(action: openSettings) {
                Text(viewModel.showReturnHelp ? "setup_try_again" : "setup_open_settings")
            }
            .buttonStyle(OnboardingPillButtonStyle())

            HStack {
                Button("Show manual setup steps") { showsManualSteps = true }
                Spacer()
                Button("setup_later") { viewModel.postpone() }
            }
            .font(.footnote)
            .foregroundColor(.white.opacity(0.55))
        }
    }

    private func linesFinished() {
        withAnimation(.easeOut) { showsVideo = true }
        if viewModel.isKeyboardAdded { onReady() }
    }

    private func openSettings() {
        viewModel.openSettingsTapped()
        openURL(URL(string: UIApplication.openSettingsURLString)!)
    }
}

struct SetupOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackground()
            SetupOnboardingView(viewModel: NewKeyboardSetupViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
