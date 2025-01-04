//
//  FirebaseService.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 04.01.2025.
//

import Foundation
import FirebaseCore
import FirebaseCrashlytics

public enum FirebaseTarget: String {
    case app
    case keyboard
}

public final class FirebaseService {
    public static let shared = FirebaseService()
    
    private init() {}
    
    public func configure(for target: FirebaseTarget) {
        // Skip if Firebase is already configured
        guard FirebaseApp.app() == nil else { return }
        
        switch target {
        case .app:
            FirebaseApp.configure()
        case .keyboard:
            // For keyboard, we need to check if default config exists first
            // as it might have been configured by main app
            if let path = Bundle.main.path(forResource: "GoogleService-Info-Keyboard", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: options)
            }
        }
        
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
        
        // Set custom key to identify which target
        setCrashlyticsKey("target", value: target.rawValue)
    }

    // MARK: - Private Methods
    
    private func setCrashlyticsKey(_ key: String, value: Any) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
}
