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
    var keyboardSetup = TextRightChevronViewModel(
        text: "Keyboard Setup",
        onTap: {
            
        }
    )
    var support = TextRightChevronViewModel(
        text: "Technical Support",
        isChevronHidden: true,
        onTap: {
            BugReporting.show(with: .question, options: [.commentFieldRequired])
        }
    )
    var reportBug = TextRightChevronViewModel(
        text: "Report a bug",
        isChevronHidden: true,
        onTap: {
            BugReporting.show(with: .bug, options: [.emailFieldOptional, .commentFieldRequired])
        }
    )
    var donateProject = TextRightChevronViewModel(
        text: "Donate to project",
        isChevronHidden: true,
        onTap: {
            
        }
    )
    var privacyPolicy = TextRightChevronViewModel(
        text: "Privacy policy",
        isChevronHidden: true,
        onTap: {
            
        }
    )

    let magicAutocorrection = MagicAutocorrectionViewModel()
}

struct MainView: View {
    @ObservedObject
    var viewModel: MainViewModel

    var body: some View {
        VStack {
            NavigationView {
                Form {
                    Section(content: {
//                        TextRightChevronView(viewModel: viewModel.language)
                        NavigationLink {
                            SettingsView(viewModel: SettingsViewModel())
                        } label: {
                            Text("Settings")
                        }
//                        TextRightChevronView(viewModel: viewModel.design)
                    })

                    autocorrectionSection

                    Section(content: {
                        NavigationLink {
                            KeyboardSelectionView(viewModel: KeyboardSelectionViewModel())
                        } label: {
                            Text("How to switch to keyboard")
                        }
                        TextRightChevronView(viewModel: viewModel.support)
                        TextRightChevronView(viewModel: viewModel.reportBug)
                    })

                    Section(
                        content: {
                            TextRightChevronView(viewModel: viewModel.donateProject)
                            TextRightChevronView(viewModel: viewModel.privacyPolicy)
                        },
                        footer: {
                            HStack {
                                Spacer()
                                Text("NeoQazaq keyboard app \(GlobalConstants.appVersion)")
                                    .font(.caption)
                                    .foregroundColor(Asset.Colors.text.swiftUIColor)
                                    .padding(.top, 16)
                                Spacer()
                            }
                        }
                    )
                }.navigationBarTitle("NeoQazaq")
            }
            
        }
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
