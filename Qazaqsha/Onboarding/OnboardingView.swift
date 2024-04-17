//
//  OnboardingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 01.03.2024.
//

import SwiftUI
import Combine
import QazaqFoundation

class OnboardingViewModel: ObservableObject {
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
        case .welcome, .keyboardSelection:
            return "Next"
        case .keyboardSetup:
            return ""
        case .magicAutocorrection:
            if magicAutocorrection?.isAutocompleteEnabled == true {
                return "Finish"
            } else {
                return "Skip"
            }
        }
    }

    var shouldShowNextButton: Bool {
        switch currentPage {
        case .welcome, .keyboardSelection, .magicAutocorrection:
            return true
        case .keyboardSetup:
            return false
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

struct OnboardingView: View {
    @ObservedObject
    var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        viewModel.magicAutocorrection = MagicAutocorrectionViewModel(
            title: "Auto-Correction",
            action: primaryButtonAction
        )
    }

    var body: some View {
        VStack {
            ForEach($viewModel.pages, id: \.self) { page in
                if page.wrappedValue == viewModel.currentPage {
                    viewModel.view(action: primaryButtonAction)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(AnyTransition.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading))
                        )
                }
            }
            .animation(.easeInOut, value: viewModel.currentPage)

            if viewModel.shouldShowNextButton {
                Button(action: primaryButtonAction, label: {
                    Text(viewModel.currentPageActionText)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(Asset.Colors.text.swiftUIColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                })
                .background(Asset.Colors.lightPrimary.swiftUIColor)
                .roundCorners(value: 8)
                .animation(.easeInOut, value: viewModel.currentPage)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                .transition(AnyTransition.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading))
                )
            }
        }
        .padding(.top, 32)
    }

    private func primaryButtonAction() {
        if viewModel.currentPage == .magicAutocorrection {
            viewModel.didFinishOnboarding = true
        } else {
            showNextPage()
        }
    }

    private func showNextPage() {
        guard
            let currentIndex = viewModel.pages.firstIndex(of: viewModel.currentPage),
            viewModel.pages.count > currentIndex + 1
        else {
            return
        }

        viewModel.currentPage = viewModel.pages[currentIndex + 1]
    }
}

struct OnboardingView_Preview: PreviewProvider {
    static let didFinishOnboarding = Binding.constant(false)

    static var previews: some View {
        OnboardingView(viewModel: OnboardingViewModel(
            currentPage: .welcome,
            pages: OnboardingPage.fullOnboarding,
            didFinishOnboarding: didFinishOnboarding
        ))
    }
}

