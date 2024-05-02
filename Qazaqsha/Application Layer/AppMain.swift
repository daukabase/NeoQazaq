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
        let currentPage: OnboardingPage = GlobalConstants.isKeyboardExtensionEnabled ? .keyboardSetup : .welcome
        main = MainViewModel()
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
        if viewModel.didFinishOnboarding && GlobalConstants.isKeyboardExtensionEnabled {
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
