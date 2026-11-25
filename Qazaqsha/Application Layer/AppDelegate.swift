//
//  AppDelegate.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 18.04.2024.
//

import SwiftUI
import QazaqFoundation
import FirebaseCore
import FirebaseCrashlytics

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Enable Crashlytics debug logging for troubleshooting dSYM issues
        #if DEBUG
        Task {
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
            await Crashlytics.crashlytics().checkForUnsentReports()
        }
        #endif

        AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(name: "app_start"))

        // Once a day: is the keyboard enabled, and does it have Full Access? This is the only way
        // to count keyboard users without Full Access (their keyboard has no network).
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { _ in
            KeyboardStatusReporter.reportIfNeeded(
                isKeyboardEnabled: GlobalConstants.isKeyboardExtensionEnabled,
                isOnboardingFinished: UserDefaults.standard.bool(forKey: UserDefaults.isOnboardingFinishedItem.key)
            )
        }

        return true
    }
}
