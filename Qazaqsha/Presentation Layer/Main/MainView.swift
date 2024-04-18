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
    var support = TextRightChevronViewModel(
        text: "Technical Support",
        isChevronHidden: false,
        onTap: {
            BugReporting.show(with: .question, options: [.commentFieldRequired])
        }
    )
    var reportBug = TextRightChevronViewModel(
        text: "Report a bug",
        isChevronHidden: false,
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
                        NavigationLink {
                            SettingsView(viewModel: SettingsViewModel())
                        } label: {
                            Text("Settings")
                        }
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
                            NavigationLink {
                                PrivacyPolicyView()
                            } label: {
                                Text("Privacy Policy")
                            }
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
