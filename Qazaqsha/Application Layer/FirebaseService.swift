////
////  FirebaseService.swift
////  Qazaqsha
////
////  Created by Daulet Almagambetov on 04.01.2025.
////
//
//import Foundation
//import FirebaseCore
//import FirebaseCrashlytics
//import QazaqFoundation
//
//public final class FirebaseService: FirebaseServiceProtocol {
//    public static let shared = FirebaseService()
//    private init() {}
//    
//    public func configure(for target: FirebaseTarget) {
//        // Only configure if Firebase isn't already configured
//        guard FirebaseApp.app() == nil else { return }
//        
//        switch target {
//        case .app:
//            FirebaseApp.configure()
//            
//        case .keyboard:
//            if let path = Bundle.main.path(forResource: "GoogleService-Info-Keyboard", ofType: "plist"),
//               let options = FirebaseOptions(contentsOfFile: path) {
//                FirebaseApp.configure(options: options)
//            }
//        }
//        
//        // Enable Crashlytics
//        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
//        
//        // Set custom key to identify which target
//        Crashlytics.crashlytics().setCustomValue(target.rawValue, forKey: "target")
//        
//        #if DEBUG
//        print("Firebase configured for target: \(target)")
//        #endif
//    }
//    
//    public func recordError(_ error: Error, additionalUserInfo: [String: Any]? = nil) {
//        Crashlytics.crashlytics().record(error: error)
//        
//        if let userInfo = additionalUserInfo {
//            for (key, value) in userInfo {
//                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
//            }
//        }
//    }
//    
//    public func setCustomKey(_ key: String, value: String) {
//        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
//    }
//}
