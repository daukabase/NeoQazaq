//
//  AppMain.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI
import QazaqFoundation

final class AppMainModel: ObservableObject {
    @Published
    var didFinishOnboarding: Bool = false {
        didSet {
            isOnboardingCompleted = didFinishOnboarding
        }
    }
    
    @Published
    var main: MainViewModel
    var onboarding: OnboardingViewModel!

    @UserDefault(item: UserDefaults.isOnboardingFinishedItem)
    private var isOnboardingCompleted

    init() {
        // Keyboard already added (e.g. reinstall): skip straight to "Try it".
        var currentPage: OnboardingPage = GlobalConstants.isKeyboardExtensionEnabled ? .tryIt : .welcome
        main = MainViewModel()
        #if DEBUG
        // QA: launch with ONBOARDING_PAGE=welcome|privacy|keyboardSetup|tryIt|finish to open that page,
        // or ONBOARDING_PAGE=main for the main screen.
        if let page = ProcessInfo.processInfo.environment["ONBOARDING_PAGE"] {
            if page == "main" {
                isOnboardingCompleted = true
            } else if let debugPage = OnboardingPage.allCases.first(where: { "\($0)" == page }) {
                currentPage = debugPage
                isOnboardingCompleted = false
            }
        }
        #endif
        didFinishOnboarding = isOnboardingCompleted
        onboarding = OnboardingViewModel(
            currentPage: currentPage,
            pages: OnboardingPage.fullOnboarding,
            onFinishOnboarding: { [weak self] _ in
                self?.didFinishOnboarding = true
            }
        )
    }
}

struct AppMain: View {
    @ObservedObject
    var viewModel: AppMainModel

    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        // After onboarding (finished or postponed) always show the main screen; it shows a banner
        // until the keyboard is added instead of trapping the user in onboarding.
        if viewModel.didFinishOnboarding {
            MainView(viewModel: viewModel.main)
        } else {
            OnboardingView(viewModel: viewModel.onboarding)
        }
    }
}

struct AppMain_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppMain(viewModel: AppMainModel())
        }
    }
}
