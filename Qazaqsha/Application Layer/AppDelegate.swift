//
//  AppDelegate.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 18.04.2024.
//

import SwiftUI
import QazaqFoundation

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AnalyticsServiceFacade.shared.configure()
        AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(name: "app_start"))

        return true
    }
}
