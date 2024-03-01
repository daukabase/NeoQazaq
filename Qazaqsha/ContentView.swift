//
//  ContentView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

class ContentViewModel: ObservableObject {
    func isKeyboardExtensionEnabled() -> Bool {
        guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("isKeyboardExtensionEnabled(): Cannot retrieve bundle identifier.")
        }

        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return false
        }

        let keyboardExtensionBundleIdentifierPrefix = appBundleIdentifier + "."
        for keyboard in keyboards {
            if keyboard.hasPrefix(keyboardExtensionBundleIdentifierPrefix) {
                return true
            }
        }

        return false
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
