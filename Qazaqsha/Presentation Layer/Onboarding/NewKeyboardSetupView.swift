//
//  NewKeyboardSetupView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 03.11.2024.
//
//  Keyboard setup shown from the main screen's "Add the keyboard" banner. The onboarding uses
//  SetupOnboardingView with the same view model. The model tracks: setup_settings_opened,
//  setup_returned_without_keyboard, setup_keyboard_detected, setup_postponed.
//

import SwiftUI
import QazaqFoundation
import Combine

final class NewKeyboardSetupViewModel: ObservableObject {
    @Published
    var isKeyboardAdded = false
    /// The user tapped "Open Settings" and hasn't added the keyboard yet.
    @Published
    private(set) var didOpenSettings = false
    /// Shown when the user returns from Settings without the keyboard.
    @Published
    private(set) var showReturnHelp = false

    /// Set by the onboarding to offer "Do it later"; nil hides the button (e.g. in the main-screen sheet).
    var onPostpone: (() -> Void)?

    init() {
        isKeyboardAdded = GlobalConstants.isKeyboardExtensionEnabled
    }

    func openSettingsTapped() {
        didOpenSettings = true
        showReturnHelp = false
        Self.track("setup_settings_opened")
    }

    /// Call whenever the app becomes active (e.g. coming back from Settings).
    func appBecameActive() {
        let isAdded = GlobalConstants.isKeyboardExtensionEnabled
        if isAdded && !isKeyboardAdded {
            Self.track("setup_keyboard_detected")
        } else if !isAdded && didOpenSettings {
            showReturnHelp = true
            Self.track("setup_returned_without_keyboard")
        }
        isKeyboardAdded = isAdded
    }

    func postpone() {
        Self.track("setup_postponed")
        onPostpone?()
    }

    private static func track(_ name: String) {
        AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(name: name))
    }
}

struct NewKeyboardSetupView: View {
    @Environment(\.openURL) var openURL

    @State var manualSetupSheetShowing = false

    @ObservedObject
    var viewModel: NewKeyboardSetupViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleView

                if viewModel.isKeyboardAdded {
                    postSetupGuide
                } else {
                    SetupVideoView()
                        .frame(maxHeight: 380)
                        .frame(maxWidth: .infinity)
                    if viewModel.showReturnHelp {
                        returnHelp
                    }
                    actions
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .animation(.easeInOut, value: viewModel.isKeyboardAdded)
            .animation(.easeInOut, value: viewModel.showReturnHelp)
        }
        .navigationBarTitle("Keyboard setup")
        .sheet(isPresented: $manualSetupSheetShowing) {
            ManualKeyboardSetupView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.appBecameActive()
        }
    }

    var titleView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Keyboard setup")
                    .font(.largeTitle.bold())
                    .foregroundColor(Asset.Colors.text.swiftUIColor)
                if viewModel.isKeyboardAdded {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.system(size: 24, weight: .bold))
                }
            }
            Text("Set up \(GlobalConstants.appName) in the Settings")
                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
        }
    }

    var postSetupGuide: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 48))
            Text("Keyboard is ready!")
                .font(.headline)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    var returnHelp: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("setup_not_there_title", systemImage: "questionmark.circle.fill")
                .font(.headline)
                .foregroundColor(.orange)
            Text("setup_not_there_body")
                .font(.subheadline)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var actions: some View {
        VStack(spacing: 12) {
            Button(action: openSettings) {
                Text(viewModel.showReturnHelp ? "setup_try_again" : "setup_open_settings")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 25))

            HStack {
                Button("Show manual setup steps") { manualSetupSheetShowing = true }
                if viewModel.onPostpone != nil {
                    Spacer()
                    Button("setup_later") { viewModel.postpone() }
                        .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                }
            }
            .font(.footnote)
            .padding(.top, 4)
        }
    }

    private func openSettings() {
        viewModel.openSettingsTapped()
        openURL(URL(string: UIApplication.openSettingsURLString)!)
    }
}

struct NewKeyboardSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NewKeyboardSetupView(viewModel: NewKeyboardSetupViewModel())
    }
}
