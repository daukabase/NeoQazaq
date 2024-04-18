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
    
    @UserDefault(item: UserDefaults.isOnboardingFinishedItem)
    private var isOnboardingCompleted

    init() {
        main = MainViewModel()
        didFinishOnboarding = isOnboardingCompleted
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
            OnboardingView(viewModel: OnboardingViewModel(
                currentPage: GlobalConstants.isKeyboardExtensionEnabled ? .keyboardSetup : .welcome,
                pages: OnboardingPage.fullOnboarding,
                didFinishOnboarding: $viewModel.didFinishOnboarding
            ))
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
