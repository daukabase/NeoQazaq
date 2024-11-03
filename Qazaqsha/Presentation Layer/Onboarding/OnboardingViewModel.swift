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

    var onFinishOnboarding: ((Bool) -> Void)?

    init(
        currentPage: OnboardingPage,
        pages: [OnboardingPage],
        onFinishOnboarding: @escaping (Bool) -> Void
    ) {
        self.currentPage = currentPage
        self.pages = pages
        self.magicAutocorrection = MagicAutocorrectionViewModel(
            title: "Auto-Correction"
        )
        self.onFinishOnboarding = onFinishOnboarding
    }

    var currentPageActionText: String {
        switch currentPage {
        case .welcome, .keyboardSelection, .keyboardSetup, .longPressForAlternative:
            return "Next"
        case .magicAutocorrection:
            return "Finish"
        }
    }

    var shouldShowNextButton: Bool {
        switch currentPage {
        case .welcome, .keyboardSelection, .magicAutocorrection, .longPressForAlternative:
            return true
        case .keyboardSetup:
            return GlobalConstants.isKeyboardExtensionEnabled
        }
    }

    @ViewBuilder
    func view() -> some View {
        switch currentPage {
        case .welcome:
            OnboardingExplanationView()
        case .keyboardSelection:
            KeyboardSelectionView(viewModel: KeyboardSelectionViewModel())
        case .magicAutocorrection:
            MagicAutocorrectionView(viewModel: magicAutocorrection ?? .init())
        case .keyboardSetup:
            NewKeyboardSetupView()
        case .longPressForAlternative:
            AlternativeCharsOnboardingView()
        }
    }
}

enum OnboardingPage: CaseIterable {
    case welcome
    case keyboardSetup
    case longPressForAlternative
    case keyboardSelection
    case magicAutocorrection

    static let fullOnboarding = OnboardingPage.allCases
}
