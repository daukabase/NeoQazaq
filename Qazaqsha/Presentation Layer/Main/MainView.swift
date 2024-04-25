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
