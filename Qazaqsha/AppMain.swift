//
//  AppMain.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI
import QazaqFoundation

class AppMainModel: ObservableObject {

    @Published
    var didFinishOnboarding: Bool = false {
        didSet {
            isOnboardingCompleted = didFinishOnboarding
        }
    }
    
    @Published
    var main: MainViewModel
    
    @UserDefault("isOnboardingFinished")
    private var isOnboardingCompleted: Bool = false

    init() {
        main = MainViewModel()
        didFinishOnboarding = isOnboardingCompleted
    }

    func isKeyboardExtensionEnabled() -> Bool {
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return false
        }
        
        return keyboards.contains(GlobalConstants.neoQazaqKeyboardExtensionIdentifier)
    }
}

struct AppMain: View {
    @ObservedObject
    var viewModel: AppMainModel

    var body: some View {
        if viewModel.didFinishOnboarding {
            MainView(viewModel: viewModel.main)
        } else {
            OnboardingView(viewModel: OnboardingViewModel(
                currentPage: viewModel.isKeyboardExtensionEnabled() ? .keyboardSelection : .welcome,
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
