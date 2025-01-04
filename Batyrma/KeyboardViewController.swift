//
//  KeyboardViewController.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import KeyboardKit
import SwiftUI
import WordSuggestionsEngine
import QazaqFoundation
import FirebaseCore
import FirebaseCrashlytics

final class KeyboardViewController: KeyboardInputViewController {
    @UserDefault(item: UserDefaults.autoCapitalizationItem)
    var isAutoCapitalizationEnabled
    @UserDefault(item: UserDefaults.isKeyClicksSoundItem)
    var isKeyClicksSoundEnabled
    
    @UserDefault(item: UserDefaults.autocompleteItem)
    var _isAutocompleteEnabled
    
    /**
     This function is called when the controller loads. Here,
     we make demo-specific service configurations.
     */
    override func viewDidLoad() {
        DispatchQueue.main.async {
            if let path = Bundle.main.path(forResource: "GoogleService-Info-Keyboard", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: options)
            }

            AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(
                name: "launch_keyboard",
                params: [
                    "name": "keyboard_extension_opened",
                    "isAutocompleteEnabled": self._isAutocompleteEnabled,
                    "isAutoCapitalizationEnabled": self.isAutoCapitalizationEnabled,
                    "isKeyClicksSoundEnabled": self.isKeyClicksSoundEnabled
                ]
            ))
        }

        QazaqWordsDatasetLoader.shared.loadData()

        services.autocompleteService = QazaqAutocompleteProvider(
            context: state.autocompleteContext
        )

        state.keyboardContext.locale = KeyboardLocale.kazakh.locale
        state.keyboardContext.isAutocapitalizationEnabled = isAutoCapitalizationEnabled
        state.feedbackContext.isAudioFeedbackEnabled = isKeyClicksSoundEnabled

        services.calloutService = QazaqCalloutService()

        let layoutService = CyrillicService(alphabeticInputSet: .russian)
        services.layoutService = layoutService

        super.viewDidLoad()
    }
    
    public override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        DispatchQueue.main.async { [weak self] in
            self?.textDidChangeAsync(textInput)
        }
    }
}
