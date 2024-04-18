//
//  AppDelegate.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 18.04.2024.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import Instabug

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        #if DEBUG
        Instabug.start(withToken: "18b727b8703dec6fece469161e9b8d1f", invocationEvents: [.shake, .screenshot])
        #else
        Instabug.start(withToken: "18b727b8703dec6fece469161e9b8d1f", invocationEvents: [.screenshot])
        #endif

        return true
    }
}
