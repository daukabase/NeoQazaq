//
//  MainView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 14.04.2024.
//

import SwiftUI
import QazaqFoundation
import Instabug

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
                            Text("Settings")
                        }
                    }, header: {
                        HStack {
                            appIcon
                            Text("NeoQazaq")
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
                    NewKeyboardSetupView()
                }
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
                    Text("NeoQazaq 🇰🇿 keyboard app \(GlobalConstants.appVersion) 💛")
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
            Button(action: {
                viewModel.keyboardSelectionShowing = true
            }, label: {
                Text("How to switch to keyboard")
            })

            Button(action: {
                viewModel.keyboardSetupShowing = true
            }, label: {
                Text("How to setupKeyboard")
            })

            Button(action: {
                BugReporting.show(with: .question, options: [.commentFieldRequired])
            }, label: {
                Text("Technical Support")
            })

            Button(action: {
                BugReporting.show(with: .bug, options: [.emailFieldOptional, .commentFieldRequired])
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
            Text("BETA: This feature is still in development and may not work as expected.")
        })
    }
    
}

struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: MainViewModel())
    }
}
