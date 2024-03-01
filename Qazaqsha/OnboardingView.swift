//
//  OnboardingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 01.03.2024.
//

import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published
    var text: String = ""

    @UserDefault("isAutocompleteEnabled", store: .localAppGroup)
    var isAutocompleteEnabled: Bool = false
}

struct OnboardingView: View {
    @ObservedObject
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .center,
               spacing: 14,
               content: {
            Toggle("Magic autocorrection🪄 [beta]", isOn: $viewModel.isAutocompleteEnabled)
            TextField("Type text here", text: $viewModel.text)
        })
        .padding(.horizontal, 24)
    }
}
