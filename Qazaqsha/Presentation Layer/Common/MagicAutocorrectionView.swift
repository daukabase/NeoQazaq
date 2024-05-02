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
    
//    let action: (() -> Void)?
    
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
        Section("Example") {
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
        Section(content: {
            TextField("Type here", text: $viewModel.text)
                .focused($isTextFieldFocused)
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isTextFieldFocused = true
                    }
                })
                .onDisappear(perform: {
                    isTextFieldFocused = false
                })
        }, header: {
            VStack(alignment: .leading) {
                HStack {
                    Text("1.")
                    Text("Switch to NeoQazaq keyboard")
                }
                HStack(alignment: .top, spacing: 8) {
                    Text("2.")
                    Text("Type \"Салем алем!\"\nto see magic happen!")
                        .multilineTextAlignment(.leading)
                }
            }
            .font(.subheadline)
            .foregroundColor(Asset.Colors.text.swiftUIColor)
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .frame(width: UIScreen.main.bounds.width - 38, alignment: .leading)
            .overlay(InnerBorder(color: Asset.Colors.text.swiftUIColor, width: 1, cornerRadius: 8))
            .padding(.bottom, 8)
        })
    }
    
    // MARK: - Toggle
    
    var autocorrectionSection: some View {
        Section(content: {
            Toggle("Magic Auto-Correction", isOn: $viewModel.isAutocompleteEnabled)
        }, header: {
            if let title = viewModel.title {
                HStack {
                    Text(title)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(Asset.Colors.text.swiftUIColor)
                        .padding(.bottom, 16)
                        .textCase(nil)

                    Spacer()
                }
            }
        }, footer: {
            Text("BETA: This feature is still in development and may not work as expected.")
        })
    }
}

struct MagicAutocorrectionView_Preview: PreviewProvider {
    static var previews: some View {
        MagicAutocorrectionView(viewModel: MagicAutocorrectionViewModel())
            .preferredColorScheme(.dark)
    }
}

struct InnerBorder: View {
    var color: Color
    var width: CGFloat
    var cornerRadius: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let rect = CGRect(x: width / 2, y: width / 2, width: geometry.size.width - width, height: geometry.size.height - width)
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            }
            .stroke(color, lineWidth: width)
        }
        .drawingGroup()
    }
}
