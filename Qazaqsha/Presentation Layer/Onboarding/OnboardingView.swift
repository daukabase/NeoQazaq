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
    @State private var isLoading = true

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    FakeLoadingView()
                }
            } else {
                content
            }
        }
        .onAppear {
            startLoading()
        }
    }

    private func startLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                isLoading = false
            }
        }
    }

    var content: some View {
        VStack {
            ForEach($viewModel.pages, id: \.self) { page in
                if page.wrappedValue == viewModel.currentPage {
                    onboardingView()
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
                .background(.blue)
                .roundCorners(value: 8)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 1, y: 2)
                .padding(16)
            }
        }
        .padding(.top, 32)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.keyboardSetupViewModel.isKeyboardAdded = GlobalConstants.isKeyboardExtensionEnabled
            
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
            NewKeyboardSetupView(viewModel: viewModel.keyboardSetupViewModel)
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
        
        OnboardingView(viewModel: OnboardingViewModel(
            currentPage: .welcome,
            pages: OnboardingPage.fullOnboarding,
            onFinishOnboarding: { _ in }
        )).preferredColorScheme(.dark)
    }
}


struct FakeLoadingView: View {
    static let iconSize = CGFloat(200)

    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme

    @State private var shadowOffsetX: CGFloat = 16
    @State private var shadowOffsetY: CGFloat = 16
    @State private var shadowOpacity: Double = 0.5
    
    let steps = [(1, -1), (-1, -1), (-1, 1), (1, 1)].reversed()

    var body: some View {
        VStack(spacing: 16) {
            appIcon.onAppear {
                animateShadow()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
        
    }

    var appIcon: some View {
        Asset.Images.appIconNoBackground.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Self.iconSize, height: Self.iconSize)
            .background(
                RoundedRectangle(cornerRadius: 25.0)
                    .fill(Color.white)
                    .frame(width: Self.iconSize / 2, height: Self.iconSize / 2)
                    .shadow(color: .blue.opacity(shadowOpacity),
                            radius: 15,
                            x: shadowOffsetX,
                            y: shadowOffsetY)
            )
    }

    var policyView: some View {
        Text("We do not collect any personal data.")
            .font(.caption)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
    }

    private func animateShadow() {
        for (index, step) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)) {
                withAnimation(Animation.easeInOut(duration: 1)) {
                    shadowOffsetX = CGFloat(step.0) * 16
                    shadowOffsetY = CGFloat(step.1) * 16
                    shadowOpacity = 0.8
                }
                if index == steps.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        animateShadow()
                    }
                }
            }
        }
    }
}
