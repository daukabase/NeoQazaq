//
//  FAQView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 22.11.2024.
//

import SwiftUI
import QazaqFoundation

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let action: () -> Void
}

final class FAQViewModel: ObservableObject {
    @Published var keyboardSelectionShowing = false
    @Published var keyboardSetupShowing = false
    
    var items: [FAQItem] {
        [
            FAQItem(question: String(localized: "faq_how_to_switch_keyboard\(GlobalConstants.appName)")) {
                self.keyboardSelectionShowing = true
            },
            FAQItem(question: String(localized: "faq_how_to_setup_keyboard\(GlobalConstants.appName)")) {
                self.keyboardSetupShowing = true
            }
        ]
    }
}

struct FAQView: View {
    @ObservedObject var viewModel: FAQViewModel
    
    var body: some View {
        Form {
            Section {
                ForEach(viewModel.items) { item in
                    Button(action: item.action) {
                        HStack {
                            Text(item.question)
                                .foregroundColor(Asset.Colors.text.swiftUIColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                                .font(.system(size: 14))
                        }
                    }
                }
            } header: {
                Text("faq_frequently_asked")
                    .textCase(nil)
            }
        }
        .navigationTitle("FAQ")
        .sheet(isPresented: $viewModel.keyboardSelectionShowing) {
            KeyboardSelectionGuideView()
        }
        .sheet(isPresented: $viewModel.keyboardSetupShowing) {
            ManualKeyboardSetupView()

        }
    }
}

#Preview {
    NavigationView {
        FAQView(viewModel: FAQViewModel())
    }
}
