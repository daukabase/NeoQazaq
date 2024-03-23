//
//  OnboardingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 01.03.2024.
//

import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published
    var text: String = ""

    @UserDefault("isAutocompleteEnabled", store: .localAppGroup)
    var isAutocompleteEnabled: Bool = false

    @FocusState
    var firstNameFieldIsFocused: Bool
}

struct OnboardingView: View {
    @ObservedObject
    var viewModel: OnboardingViewModel
    @FocusState var hasFocus: Bool

    var body: some View {
        VStack(alignment: .center,
               spacing: 14,
               content: {
            Toggle("Magic autocorrection🪄 [beta]", isOn: $viewModel.isAutocompleteEnabled)
            TextField("Type text here", text: $viewModel.text)
                .focused($hasFocus)
        })
        .padding(.horizontal, 24)
    }
}
