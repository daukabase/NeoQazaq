//
//  MagicAutocorrectionView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 15.04.2024.
//

import SwiftUI
import QazaqFoundation

final class MagicAutocorrectionViewModel: ObservableObject {
    @UserDefault(item: UserDefaults.autocompleteItem)
    var isAutocompleteEnabledWrapper

    @Published
    var isKeyboardGuidePresented: Bool = false

    @Published
    var showCorrectionIndicator: Bool = false

    @Published
    var isAutocompleteEnabled: Bool = false {
        didSet {
            isAutocompleteEnabledWrapper = isAutocompleteEnabled
            AnalyticsServiceFacade.shared.track(
                event: CommonAnalyticsEvent(
                    name: "toggle_magic_autocorrection",
                    params: ["isEnabled": isAutocompleteEnabled]
                )
            )
        }
    }

    let title: String?

    @Published
    var text: String = ""

    @ObservedObject
    var keyboardResponder = KeyboardResponder()
    
    init(title: String? = nil) {
        self.title = title
        isAutocompleteEnabled = isAutocompleteEnabledWrapper
    }
}

struct MagicAutocorrectionView: View {
    @ObservedObject
    var viewModel: MagicAutocorrectionViewModel
    
    @Environment(\.colorScheme)
    private var isDarkMode: ColorScheme
    
    @FocusState
    var isTextFieldFocused: Bool
    
    var body: some View {
        Form {
            autocorrectionSection
            if viewModel.isAutocompleteEnabled {
                autocompleteEnabledContent
            } else {
                autocompleteExample
            }
        }
        .navigationTitle(!viewModel.isAutocompleteEnabled ? "How it works" : "Try it by yourself")
        .animation(.easeInOut, value: viewModel.isAutocompleteEnabled)
    }
    
    // MARK: - Example On Autocomplete Off
    
    @ViewBuilder
    var autocompleteExample: some View {
        Section("common_example") {
            gifAutocorrectionExample.clipped()
        }.listRowInsets(EdgeInsets())

        Section {
            Button(action: {
                viewModel.isAutocompleteEnabled = true
            }, label: {
                HStack {
                    Spacer()
                    Text("Try it out!")
                        .font(.title3)
                        .foregroundColor(Asset.Colors.text.swiftUIColor)
                    Spacer()
                }
            })
        }
    }
    
    var gifAutocorrectionExample: some View {
        let ratio = 1.16078431
        let width = UIScreen.main.bounds.width - 32
        let height = width / ratio
        
        let gifName = isDarkMode == .dark ? "autocorrectionExampleDark" : "autocorrectionExampleWhite"
        
        return GifImage(name: gifName)
            .frame(width: width, height: height)
    }
    
    // MARK: - Autocomplete On
    @ViewBuilder
    var autocompleteEnabledContent: some View {
        Section {
            VStack(alignment: .leading) {
                HStack {
                    Text("autocomplete_explanation_step_one\(GlobalConstants.appName)")
                    
                    Button {
                        viewModel.isKeyboardGuidePresented = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(Asset.Colors.lightAction.swiftUIColor)
                    }
                    .sheet(isPresented: $viewModel.isKeyboardGuidePresented) {
                        KeyboardSelectionGuideView()
                    }
                }
                
                // Step 2: Example
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("2. Try typing these:")
                    makeExampleRow(input: "Салем", output: "Сәлем")
                    makeExampleRow(input: "Кандай", output: "Қандай")
                }
                .padding(.top, 4)
            }
        }

        Section {
            TextField("Type here", text: $viewModel.text)
                .focused($isTextFieldFocused)
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isTextFieldFocused = true
                    }
                })
        }
    }

    private func makeExampleRow(input: String, output: String) -> some View {
        HStack {
            Text(input)
                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
            Image(systemName: "arrow.right")
                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
            Text(output)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
        }
    }
    
    // MARK: - Toggle
    
    var autocorrectionSection: some View {
        Section(content: {
            Toggle("Magic Auto-Correction", isOn: $viewModel.isAutocompleteEnabled)
        }, footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Auto-corrects Qazaq words as you type")
                    .font(.footnote)
                    .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                    .lineLimit(nil)
                Text("common_beta_magic_autocorrection")
                    .font(.footnote)
                    .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                    .padding(.top, 4)
                    .lineLimit(nil)
            }
        })
    }
}

struct MagicAutocorrectionView_Preview: PreviewProvider {
    static var previews: some View {
        MagicAutocorrectionView(viewModel: MagicAutocorrectionViewModel())
            .preferredColorScheme(.dark)
    }
}
