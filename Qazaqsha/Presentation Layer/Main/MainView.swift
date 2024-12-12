//
//  MainView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 14.04.2024.
//

import SwiftUI
import QazaqFoundation
import MessageUI
import StoreKit

final class MainViewModel: ObservableObject {
    @Published
    var keyboardSelectionShowing = false
    @Published
    var keyboardSetupShowing = false
    
    var donateProject = TextRightChevronViewModel(
        text: "Donate to project",
        isChevronHidden: true,
        onTap: {
            
        }
    )
    let magicAutocorrection = MagicAutocorrectionViewModel()
    
    private let lastReviewRequestKey = "lastReviewRequest"
    private let appLaunchCountKey = "appLaunchCount"

    func shouldRequestReview() -> Bool {
        let defaults = UserDefaults.standard
        
        // Increment launch count
        let launchCount = (defaults.integer(forKey: appLaunchCountKey) + 1)
        defaults.set(launchCount, forKey: appLaunchCountKey)
        
        let lastRequest = defaults.object(forKey: lastReviewRequestKey) as? Date
        
        var shouldRequest = false
        if let lastRequest {
            // Request review if last request was 2+ days ago
            if let days = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day, days >= 2 {
                shouldRequest = true
            }
        } else if launchCount >= 2 {
            // First time request: show after 2nd launch
            shouldRequest = true
        }
        
        if shouldRequest {
            defaults.set(Date(), forKey: lastReviewRequestKey)
        }
        
        return shouldRequest
    }
}

final class AppReviewRequestManager {
    private let lastReviewRequestKey = "lastReviewRequest"
    private let appLaunchCountKey = "appLaunchCount"

    func shouldRequestReview() -> Bool {
        let defaults = UserDefaults.standard
        
        // Increment launch count
        let launchCount = (defaults.integer(forKey: appLaunchCountKey) + 1)
        defaults.set(launchCount, forKey: appLaunchCountKey)
        
        let lastRequest = defaults.object(forKey: lastReviewRequestKey) as? Date
        
        var shouldRequest = false
        if let lastRequest {
            // Request review if last request was 2+ days ago
            if let days = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day, days >= 2 {
                shouldRequest = true
            }
        } else if launchCount >= 2 {
            // First time request: show after 2nd launch
            shouldRequest = true
        }
        
        if shouldRequest {
            defaults.set(Date(), forKey: lastReviewRequestKey)
        }
        
        return shouldRequest
    }
}

struct MainView: View {
    static let iconSize = CGFloat(100)
    @ObservedObject
    var viewModel: MainViewModel

    var body: some View {
        VStack {
            NavigationView {
                Form {
                    Section(content: {
                        NavigationLink {
                            SettingsView(viewModel: SettingsViewModel())
                        } label: {
                            Text(String(localized: "settings"))
                        }
                    }, header: {
                        HStack {
                            appIcon
                            Text(String(localized: "app_name"))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.text)
                            Spacer()
                        }
                        .textCase(nil)
                        .listRowInsets(EdgeInsets())
                    })
                        

                    autocorrectionSection
                    actionsSection

                    footerSection
                }
                .sheet(isPresented: $viewModel.keyboardSelectionShowing) {
                    KeyboardSelectionGuideView()
                }
                .sheet(isPresented: $viewModel.keyboardSetupShowing) {
                    NewKeyboardSetupView(viewModel: {
                        let model = NewKeyboardSetupViewModel()
                        model.isKeyboardAdded = GlobalConstants.isKeyboardExtensionEnabled
                        return model
                    }())
                }
            }
        }.onAppear {
            DispatchQueue.main.async {
                AppReviewService.shared.requestReviewIfNeeded()
            }
        }
    }
    
    var appIcon: some View {
        Asset.Images.appIconNoBackground.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Self.iconSize, height: Self.iconSize)
            .background(
                RoundedRectangle(cornerRadius: 25.0)
                    .frame(width: Self.iconSize / 2, height: Self.iconSize / 2)
                    .foregroundStyle(.white)
                    .shadow(color: .blue, radius: 15, x: -8, y: 8)
            )
    }

    var footerSection: some View {
        Section(
            content: {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Text("Privacy Policy")
                }
            },
            footer: {
                HStack {
                    Spacer()
                    Text("keyboard_app\(GlobalConstants.appVersion)")
                        .font(.caption)
                        .foregroundColor(Asset.Colors.text.swiftUIColor)
                        .padding(.top, 16)
                    Spacer()
                }
            }
        )
    }
    var actionsSection: some View {
        Section(content: {
            NavigationLink {
                FAQView(viewModel: FAQViewModel())
            } label: {
                Text("FAQ")
            }


            Button(action: {
                presentFeedback(.question)  // Using our new FeedbackService
            }, label: {
                Text("tech_support")
            })

            Button(action: {
                presentFeedback(.bug)  // Using our new FeedbackService
            }, label: {
                Text("Report a bug")
            })
        })
    }

    var autocorrectionSection: some View {
        Section(content: {
            NavigationLink {
                MagicAutocorrectionView(viewModel: viewModel.magicAutocorrection)
            } label: {
                Text("Magic Auto-Correction")
            }
        }, footer: {
            Text("common_beta_magic_autocorrection")
        })
    }
    
    var faqSection: some View {
        Section {
            NavigationLink {
                MagicAutocorrectionView(viewModel: viewModel.magicAutocorrection)
            } label: {
                Text("FAQ")
            }
        }
    }
}

struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: MainViewModel())
    }
}
