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
            AnalyticsServiceFacade.shared.configure()

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
        services.calloutService = QazaqCalloutService()

        let layoutService = CyrillicService(alphabeticInputSet: .russian)
        layoutService.localeKey = KeyboardLocale.russian.id
        services.layoutService = layoutService

        super.viewDidLoad()
    }
}
