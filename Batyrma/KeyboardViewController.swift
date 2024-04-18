//
//  KeyboardViewController.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import KeyboardKit
import SwiftUI
import WordSuggestionsEngine
import FirebaseCore
import FirebaseAnalytics

/**
 This keyboard demonstrates how to setup KeyboardKit and how
 to customize the standard configuration.

 To use this keyboard, you must enable it in system settings
 ("Settings/General/Keyboards"). It needs full access to get
 access to features like haptic feedback.
 */

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
        FirebaseApp.configure()

        Analytics.logEvent("launch_keybaord", parameters: [
            "name": "keyboard_extension_opened",
            "isAutocompleteEnabled": _isAutocompleteEnabled,
            "isAutoCapitalizationEnabled": isAutoCapitalizationEnabled,
            "isKeyClicksSoundEnabled": isKeyClicksSoundEnabled
        ])

        QazaqWordsDatasetLoader.shared.loadData()
        /// 💡 Setup a fake autocomplete provider.
        ///
        /// This fake provider will provide fake suggestions.
        /// Try the Pro demo for real suggestions.
        services.autocompleteProvider = QazaqAutocompleteProvider(
            context: state.autocompleteContext
        )
        
        /// 💡 Setup a demo-specific callout action provider.
        ///
        /// The demo provider adds "keyboard" callout action
        /// buttons to the "k" key.
        services.calloutActionProvider = StandardCalloutActionProvider(keyboardContext: state.keyboardContext)
        
        /// 💡 Setup a demo-specific layout provider.
        ///
        /// The demo provider adds a "next locale" button if
        /// needed, as well as a rocket emoji button.
        services.layoutProvider = StandardKeyboardLayoutProvider(
            baseProvider: NeoQazaqKeyboardLayoutProvider()
        )

        /// 💡 Setup a custom keyboard locale.
        ///
        /// Without KeyboardKit Pro, changing locale will by
        /// default only affects localized texts.
        state.keyboardContext.setLocale(.kazakh)

        /// 💡 Add more locales to the keyboard.
        ///
        /// The demo layout provider will add a "next locale"
        /// button if you have more than one locale.
        state.keyboardContext.localePresentationLocale = KeyboardLocale.kazakh.locale
        state.keyboardContext.locales = [KeyboardLocale.kazakh.locale]

        /// 💡 Configure the space long press behavior.
        ///
        /// The locale context menu will only open up if the
        /// keyboard has multiple locales.
        state.keyboardContext.spaceLongPressBehavior = .moveInputCursor
        
        if !isAutoCapitalizationEnabled {
            state.keyboardContext.autocapitalizationTypeOverride = nil
        }

        if !isKeyClicksSoundEnabled {
            state.feedbackConfiguration.isAudioFeedbackEnabled = false
        }

        /// 💡 Setup audio and haptic feedback.
        ///
        /// The code below enabled haptic feedback and plays
        /// a rocket sound when a rocket button is tapped.
        state.feedbackConfiguration.isHapticFeedbackEnabled = true
        
        /// 💡 Call super to perform the base initialization.
        super.viewDidLoad()
    }

    override func viewWillSetupKeyboard() {
        super.viewWillSetupKeyboard()
        setup { controller in
            SystemKeyboard(
                state: controller.state,
                services: controller.services,
                buttonContent: { $0.view },
                buttonView: { $0.view },
                emojiKeyboard: { $0.view },
                toolbar: { $0.view }
            )
        }
    }
}
