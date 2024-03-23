//
//  ContentView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI


class ContentViewModel: ObservableObject {
    private enum Constants {
        static let neoQazaqKeyboardExtensionIdentifier = "com.almagambetov.daulet.qazaqsha.Qazaqsha.NeoQazaq"
    }
    func isKeyboardExtensionEnabled() -> Bool {
        guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("isKeyboardExtensionEnabled(): Cannot retrieve bundle identifier.")
        }

        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return false
        }

        return keyboards.contains(Constants.neoQazaqKeyboardExtensionIdentifier)
    }
}

struct ContentView: View {
    @ObservedObject
    var viewModel: ContentViewModel

    @Environment(\.openURL) var openURL

    var body: some View {
        if viewModel.isKeyboardExtensionEnabled() {
            OnboardingView(viewModel: OnboardingViewModel())
        } else {
            AppSetupView().onAppear(perform: {
                
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ContentView(viewModel: ContentViewModel())
        }
    }
}
