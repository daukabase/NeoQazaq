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
    var reload = false

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
        case .welcome, .keyboardSetup, .longPressForAlternative:
            return "Next"
        case .magicAutocorrection:
            return "Finish"
        }
    }

    var shouldShowNextButton: Bool {
        switch currentPage {
        case .welcome, .magicAutocorrection, .longPressForAlternative:
            return true
        case .keyboardSetup:
            return GlobalConstants.isKeyboardExtensionEnabled
        }
    }
}

enum OnboardingPage: CaseIterable {
    case welcome
    case longPressForAlternative
    case keyboardSetup
    case magicAutocorrection

    static let fullOnboarding = OnboardingPage.allCases
}
