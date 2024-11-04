//
//  OnboardingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 01.03.2024.
//

import SwiftUI
import QazaqFoundation

struct OnboardingView: View {
    @ObservedObject
    var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ForEach($viewModel.pages, id: \.self) { page in
                if page.wrappedValue == viewModel.currentPage {
                    onboardingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(AnyTransition.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading))
                        )
                        .onAppear(perform: {
                            switch viewModel.currentPage {
                            case .keyboardSetup:
                                AnalyticsServiceFacade.shared.track(
                                    event: CommonAnalyticsEvent(name: "onboarding_keyboard_setup")
                                )
                            case .magicAutocorrection:
                                AnalyticsServiceFacade.shared.track(
                                    event: CommonAnalyticsEvent(name: "onboarding_magic_autocorrection")
                                )
                            case .welcome:
                                AnalyticsServiceFacade.shared.track(
                                    event: CommonAnalyticsEvent(name: "onboarding_welcome")
                                )
                            case .longPressForAlternative:
                                AnalyticsServiceFacade.shared.track(
                                    event: CommonAnalyticsEvent(name: "onboarding_alternative_char_long_press")
                                )
                            case .finish:
                                AnalyticsServiceFacade.shared.track(
                                    event: CommonAnalyticsEvent(name: "onboarding_finish")
                                )
                            }
                        })
                }
            }
            .animation(.easeInOut, value: viewModel.currentPage)

            if viewModel.reload {
                EmptyView().frame(width: 0, height: 0)
            }
            if viewModel.shouldShowNextButton {
                Button(action: primaryButtonAction, label: {
                    Text(viewModel.currentPageActionText)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                })
                .animation(.easeInOut(duration: 1))
                .background(.blue)
                .roundCorners(value: 8)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 1, y: 2)
                .padding(16)
                .transition(AnyTransition.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading))
                )
            }
        }
        .padding(.top, 32)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.reload.toggle()
        }
    }

    @ViewBuilder
    func onboardingView() -> some View {
        switch viewModel.currentPage {
        case .welcome:
            OnboardingExplanationView()
        case .magicAutocorrection:
            MagicAutocorrectionView(viewModel: viewModel.magicAutocorrection ?? .init())
        case .keyboardSetup:
            NewKeyboardSetupView()
        case .longPressForAlternative:
            AlternativeCharsOnboardingView()
        case .finish:
            FinishOnboardingView()
        }
    }

    private func primaryButtonAction() {
        if viewModel.currentPage == .finish {
            viewModel.onFinishOnboarding?(true)
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
    static let didFinishOnboarding = Published(initialValue: false)

    static var previews: some View {
        OnboardingView(viewModel: OnboardingViewModel(
            currentPage: .welcome,
            pages: OnboardingPage.fullOnboarding,
            onFinishOnboarding: { _ in }
        ))
    }
}

