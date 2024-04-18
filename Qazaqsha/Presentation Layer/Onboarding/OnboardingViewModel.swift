//
//  OnboardingViewModel.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 17.04.2024.
//

import SwiftUI
import Combine
import QazaqFoundation

final class OnboardingViewModel: ObservableObject {
    @Published
    var currentPage: OnboardingPage = .welcome
    @Published
    var pages: [OnboardingPage]

    @Published
    var magicAutocorrection: MagicAutocorrectionViewModel?

    @Binding
    var didFinishOnboarding: Bool

    init(
        currentPage: OnboardingPage,
        pages: [OnboardingPage],
        didFinishOnboarding: Binding<Bool>
    ) {
        self.currentPage = currentPage
        self.pages = pages
        self._didFinishOnboarding = didFinishOnboarding
    }

    var currentPageActionText: String {
        switch currentPage {
        case .welcome, .keyboardSelection, .keyboardSetup:
            return "Next"
        case .magicAutocorrection:
            return "Finish"
        }
    }

    var shouldShowNextButton: Bool {
        switch currentPage {
        case .welcome, .keyboardSelection, .magicAutocorrection:
            return true
        case .keyboardSetup:
            return GlobalConstants.isKeyboardExtensionEnabled
        }
    }

    @ViewBuilder
    func view(action: @escaping () -> Void) -> some View {
        switch currentPage {
        case .welcome:
            OnboardingExplanationView()
        case .keyboardSelection:
            KeyboardSelectionView(viewModel: KeyboardSelectionViewModel())
        case .magicAutocorrection:
            MagicAutocorrectionView(viewModel: magicAutocorrection ?? .init())
        case .keyboardSetup:
            KeyboardSetupView()
        }
    }
}

enum OnboardingPage: CaseIterable {
    case welcome
    case keyboardSetup
    case keyboardSelection
    case magicAutocorrection

    static let fullOnboarding = OnboardingPage.allCases
}
