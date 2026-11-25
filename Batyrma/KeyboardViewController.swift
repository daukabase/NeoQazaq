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

    /// Words the user taught the keyboard and corrections they undid. Device-only.
    private let personalStore = PersonalStore()

    /// Opens and on-screen time per day (numbers only), reported with the daily analytics event.
    private let usageCounter = KeyboardUsageCounter()
    private var appearedAt: Date?

    /**
     This function is called when the controller loads. Here,
     we make demo-specific service configurations.
     */
    override func viewDidLoad() {
        // Start memory-pressure monitoring first, before anything else allocates memory, so we have
        // coverage for the entire extension lifetime.
        MemoryPressureMonitor.shared.start()

        setupKeyboardServices()

        super.viewDidLoad()

        setupAsyncServices()
    }

    /// KeyboardKit rebuilds the keyboard view on every appearance; pick up a skin chosen in the app meanwhile.
    override func viewWillAppear(_ animated: Bool) {
        applySkin()
        usageCounter.recordOpen()
        appearedAt = Date()
        super.viewWillAppear(animated)
    }

    /// The standard keyboard, with the suggestion bar in the skin's colour scheme so suggestions stay
    /// readable on light skins in dark apps (see `SkinStyleService.toolbarColorScheme`).
    override func viewWillSetupKeyboardView() {
        setupKeyboardView { controller in
            KeyboardView(
                state: controller.state,
                services: controller.services,
                buttonContent: { $0.view },
                buttonView: { $0.view },
                collapsedView: { $0.view },
                emojiKeyboard: { $0.view },
                toolbar: { params in
                    let scheme = (controller.services.styleService as? SkinStyleService)?.toolbarColorScheme
                    params.view.environment(\.colorScheme, scheme ?? controller.state.keyboardContext.colorScheme)
                }
            )
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let appearedAt {
            usageCounter.recordVisible(seconds: Date().timeIntervalSince(appearedAt))
            self.appearedAt = nil
        }
        super.viewWillDisappear(animated)
    }
}

private extension KeyboardViewController {
    func setupKeyboardServices() {
        // "Reset learned words" in the app writes a new token to the app group (readable without Full Access).
        personalStore.resetIfRequested(
            token: UserDefaults.localAppGroup.string(forKey: UserDefaults.personalStoreResetTokenKey)
        )

        // Setup core keyboard functionality first
        services.autocompleteService = QazaqAutocompleteProvider(
            store: personalStore,
            russianSpellChecker: RussianSpellChecker()
        )
        // Tapping the as-typed suggestion teaches the keyboard that word.
        state.autocompleteContext.settings.isAutolearnEnabled = true

        state.keyboardContext.locale = Locale.kazakh
        state.keyboardContext.settings.isAutocapitalizationEnabled = isAutoCapitalizationEnabled
        state.feedbackContext.settings.isAudioFeedbackEnabled = isKeyClicksSoundEnabled

        services.calloutService = QazaqCalloutService()

        let layoutService = CyrillicService(alphabeticInputSet: .russian)
        services.layoutService = layoutService

        // Must come after the autocomplete service: the handler captures it on init.
        services.actionHandler = QazaqActionHandler(controller: self, store: personalStore)

        applySkin()
    }

    /// Skins are chosen (and bought) in the app, which writes the choice to the app group.
    func applySkin() {
        let skin = KeyboardSkin.current()
        if (services.styleService as? SkinStyleService)?.skin == skin { return }
        services.styleService = SkinStyleService(keyboardContext: state.keyboardContext, skin: skin)
    }

    func setupAsyncServices() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Configure Firebase
            if FirebaseApp.app() == nil,
               let path = Bundle.main.path(forResource: "GoogleService-Info-Keyboard", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: options)
            }

            // Proof for the app that this keyboard runs with Full Access (the write fails without it).
            KeyboardStatusReporter.markFullAccessIfGranted(hasFullAccess: self.hasFullAccess)
            self.trackKeyboardLaunchOncePerDay()
        }
    }

    /// The keyboard loads many times a day; one event per day is enough for daily-active and
    /// retention charts, and avoids creating the Amplitude client (memory) on every load.
    func trackKeyboardLaunchOncePerDay() {
        let key = "lastLaunchKeyboardEventDay"
        let today = Calendar.current.startOfDay(for: Date())
        if let last = UserDefaults.standard.object(forKey: key) as? Date, last >= today { return }
        UserDefaults.standard.set(today, forKey: key)

        var params: [String: Any] = [
            "name": "keyboard_extension_opened",
            "isAutocompleteEnabled": _isAutocompleteEnabled,
            "isAutoCapitalizationEnabled": isAutoCapitalizationEnabled,
            "isKeyClicksSoundEnabled": isKeyClicksSoundEnabled,
            "hasFullAccess": hasFullAccess
        ]
        // The last active day's totals (one event a day, so engagement still shows in Amplitude).
        if let usage = usageCounter.takeFinishedDay() {
            params["prevDayOpens"] = usage.opens
            params["prevDayVisibleSeconds"] = usage.visibleSeconds
        }
        AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(name: "launch_keyboard", params: params))
    }
}
