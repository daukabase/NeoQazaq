//
//  MainView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 14.04.2024.
//

import SwiftUI
import QazaqFoundation

final class MainViewModel: ObservableObject {
    var language = TextRightChevronViewModel(
        text: "Language",
        onTap: {
            
        }
    )
    var settings = TextRightChevronViewModel(
        text: "Settings",
        onTap: {
            
        }
    )
    var design = TextRightChevronViewModel(
        text: "Design",
        onTap: {
            
        }
    )
    var faq = TextRightChevronViewModel(
        text: "FAQ",
        onTap: {
            
        }
    )
    var support = TextRightChevronViewModel(
        text: "Technical Support",
        isChevronHidden: true,
        onTap: {
            
        }
    )
    var reportBug = TextRightChevronViewModel(
        text: "Report a bug",
        isChevronHidden: true,
        onTap: {
            
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
}

struct MainView: View {
    @ObservedObject
    var viewModel: MainViewModel

    var body: some View {
        VStack {
            NavigationView {
                Form {
                    Section(content: {
                        TextRightChevronView(viewModel: viewModel.language)
                        NavigationLink {
                            SettingsView(viewModel: SettingsViewModel())
                        } label: {
                            Text("Settings")
//                            TextRightChevronView(viewModel: viewModel.settings)
                        }
                        TextRightChevronView(viewModel: viewModel.design)
                    })

                    Section(content: {
                        TextRightChevronView(viewModel: viewModel.faq)
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
}

struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: MainViewModel())
    }
}
