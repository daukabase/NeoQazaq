//
//  OnboardingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 01.03.2024.
//

import SwiftUI
import QazaqFoundation

/// Shared template for every onboarding page (Opal-style): dark sky, Batyrma's orb on top,
/// the conversation in the middle, one white button at the bottom once Batyrma has finished.
struct OnboardingView: View {
    @ObservedObject
    var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                if let index = viewModel.progressIndex {
                    OnboardingProgressBar(count: OnboardingPage.steps.count, current: index)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                BatyrmaOrb(size: viewModel.currentPage == .keyboardSetup ? 56 : 80)
                    .padding(.top, 8)
                    .animation(.spring(), value: viewModel.currentPage)

                page
                    .id(viewModel.currentPage)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .onAppear {
                        AnalyticsServiceFacade.shared.track(
                            event: CommonAnalyticsEvent(name: viewModel.currentPage.analyticsEvent)
                        )
                    }

                if let title = viewModel.primaryButtonTitle {
                    Button(title) {
                        withAnimation { viewModel.primaryButtonTapped() }
                    }
                    .buttonStyle(OnboardingPillButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut, value: viewModel.currentPage)
        .animation(.easeOut, value: viewModel.isPageReady)
    }

    @ViewBuilder
    private var page: some View {
        switch viewModel.currentPage {
        case .welcome:
            WelcomeOnboardingView(onReady: viewModel.pageReady)
        case .privacy:
            PrivacyOnboardingView(onReady: viewModel.pageReady)
        case .keyboardSetup:
            SetupOnboardingView(viewModel: viewModel.keyboardSetupViewModel, onReady: viewModel.pageReady)
        case .tryIt:
            TryItOnboardingView(onReady: viewModel.pageReady)
        case .finish:
            FinishOnboardingView(onReady: viewModel.pageReady)
        }
    }
}

struct OnboardingView_Preview: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: OnboardingViewModel(
            currentPage: .welcome,
            pages: OnboardingPage.fullOnboarding,
            onFinishOnboarding: { _ in }
        ))
        OnboardingView(viewModel: OnboardingViewModel(
            currentPage: .tryIt,
            pages: OnboardingPage.fullOnboarding,
            onFinishOnboarding: { _ in }
        )).preferredColorScheme(.dark)
    }
}
