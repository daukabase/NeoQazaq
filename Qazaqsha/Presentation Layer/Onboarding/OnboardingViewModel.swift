//
//  OnboardingViewModel.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 17.04.2024.
//

import SwiftUI
import Combine
import QazaqFoundation

/// Onboarding: a conversation with Batyrma in four steps (welcome → privacy → add the
/// keyboard → try it), then a done screen. Adding the keyboard used to come third and lose 39% of users.
enum OnboardingPage: CaseIterable {
    case welcome
    case privacy
    case keyboardSetup
    case tryIt
    case finish

    static let fullOnboarding = OnboardingPage.allCases

    /// Pages shown with progress dots (the done screen has none).
    static let steps: [OnboardingPage] = [.welcome, .privacy, .keyboardSetup, .tryIt]

    /// Analytics event sent when the page appears. Existing names are kept so funnels continue.
    var analyticsEvent: String {
        switch self {
        case .welcome: return "onboarding_welcome"
        case .privacy: return "onboarding_privacy"
        case .keyboardSetup: return "onboarding_keyboard_setup"
        case .tryIt: return "onboarding_try_it"
        case .finish: return "onboarding_finish"
        }
    }
}

final class OnboardingViewModel: ObservableObject {
    @Published
    var currentPage: OnboardingPage {
        didSet { if currentPage != oldValue { isPageReady = false } }
    }
    /// The page finished talking; only then the main button appears (Opal-style pacing).
    @Published
    var isPageReady = false

    let pages: [OnboardingPage]
    let keyboardSetupViewModel: NewKeyboardSetupViewModel
    var onFinishOnboarding: ((Bool) -> Void)?
    private var cancellables = Set<AnyCancellable>()

    init(
        currentPage: OnboardingPage,
        pages: [OnboardingPage],
        onFinishOnboarding: @escaping (Bool) -> Void
    ) {
        self.currentPage = currentPage
        self.pages = pages
        self.keyboardSetupViewModel = NewKeyboardSetupViewModel()
        self.onFinishOnboarding = onFinishOnboarding

        // The primary button depends on the nested setup model; refresh when the keyboard gets added.
        keyboardSetupViewModel.$isKeyboardAdded
            .removeDuplicates()
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        // "Do it later": go to the main screen, which keeps reminding with a banner.
        keyboardSetupViewModel.onPostpone = { [weak self] in
            self?.onFinishOnboarding?(false)
        }
    }

    /// Title of the bottom button, or nil to hide it (setup page until the keyboard is added;
    /// that page has its own "Open Settings" button).
    var primaryButtonTitle: String? {
        guard isPageReady else { return nil }
        switch currentPage {
        case .welcome:
            return String(localized: "onboarding_get_started")
        case .privacy:
            return String(localized: "privacy_got_it")
        case .keyboardSetup:
            return keyboardSetupViewModel.isKeyboardAdded ? String(localized: "next") : nil
        case .tryIt:
            return String(localized: "next")
        case .finish:
            return String(localized: "start_using\(GlobalConstants.appName)")
        }
    }

    /// Position in the progress dots, or nil on the done screen.
    var progressIndex: Int? {
        OnboardingPage.steps.firstIndex(of: currentPage)
    }

    func pageReady() {
        isPageReady = true
    }

    func primaryButtonTapped() {
        guard currentPage != .finish else {
            onFinishOnboarding?(true)
            return
        }
        if let index = pages.firstIndex(of: currentPage), index + 1 < pages.count {
            currentPage = pages[index + 1]
        }
    }
}
