//
//  MagicAutocorrectionView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 15.04.2024.
//

import SwiftUI
import QazaqFoundation

final class MagicAutocorrectionViewModel: ObservableObject {
    @UserDefault("isAutocompleteEnabled", store: .localAppGroup)
    var isAutocompleteEnabledWrapper: Bool = false

    @Published
    var isAutocompleteEnabled: Bool = false {
        didSet {
            isAutocompleteEnabledWrapper = isAutocompleteEnabled
        }
    }

    @Published
    var text: String = ""

    @ObservedObject
    var keyboardResponder = KeyboardResponder()

    init() {
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
        NavigationView {
            Form {
                autocorrectionSection
                if viewModel.isAutocompleteEnabled {
                    autocompleteEnabledContent
                        .padding(.bottom, viewModel.keyboardResponder.currentHeight)
                } else {
                    autocompleteExample
                }
            }
            .navigationTitle(!viewModel.isAutocompleteEnabled ? "How it works" : "Try it by yourself")
            .animation(.easeInOut, value: viewModel.isAutocompleteEnabled)
        }
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
                    isTextFieldFocused = true
                })
                .onDisappear(perform: {
                    isTextFieldFocused = false
                })
        }, header: {
            VStack(alignment: .leading) {
                Text("1. Select NeoQazaq keyboard")
                Text("2. Type \"Салем алем!\"\n    to see magic happen!")
            }
            .foregroundColor(Asset.Colors.text.swiftUIColor)
            .padding(.vertical, 12)
                .padding(.leading, 16)
                .frame(width: UIScreen.main.bounds.width - 38, alignment: .leading)
                .background(Asset.Colors.lightPrimary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                .padding(.bottom, 8)
                
        })
    }

    // MARK: - Toggle

    var autocorrectionSection: some View {
        Section(content: {
            Toggle("Magic Auto-Correction", isOn: $viewModel.isAutocompleteEnabled)
        }, footer: {
            Text("BETA: This feature is still in development and may not work as expected.")
        })
    }
}

struct MagicAutocorrectionView_Preview: PreviewProvider {
    static var previews: some View {
        MagicAutocorrectionView(viewModel: MagicAutocorrectionViewModel())
    }
}

struct ResponderTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    @FocusState var isFocused: Bool

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        print(uiView.isHidden)
        print(uiView.layer.opacity)

        uiView.text = text
        uiView.becomeFirstResponder()
    }
}
