//
//  AppMain.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

class AppMainModel: ObservableObject {
    private enum Constants {
        static let neoQazaqKeyboardExtensionIdentifier = "com.almagambetov.daulet.qazaqsha.Qazaqsha.NeoQazaq"
    }

    func isKeyboardExtensionEnabled() -> Bool {
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return false
        }

        return keyboards.contains(Constants.neoQazaqKeyboardExtensionIdentifier)
    }
}

struct AppMain: View {
    @ObservedObject
    var viewModel: AppMainModel

    var body: some View {
        if viewModel.isKeyboardExtensionEnabled() {
            OnboardingView(viewModel: OnboardingViewModel())
        } else {
            KeyboardSetupView().onAppear(perform: {
                
            })
        }
    }
}

struct AppMain_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppMain(viewModel: AppMainModel())
        }
    }
}
