//
//  AppReviewService.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 12.12.2024.
//

import Foundation
import StoreKit

final class AppReviewService {
    static let shared = AppReviewService()
    
    private let lastReviewRequestKey = "lastReviewRequest"
    private let appLaunchCountKey = "appLaunchCount"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func shouldRequestReview() -> Bool {
        let launchCount = (defaults.integer(forKey: appLaunchCountKey) + 1)
        defaults.set(launchCount, forKey: appLaunchCountKey)

        let lastRequest = defaults.object(forKey: lastReviewRequestKey) as? Date

        var shouldRequest = false
        if launchCount >= 2 {
            // First time request: show after 2nd launch
            shouldRequest = true
        }

        if let lastRequest {
            // Request review if last request was 2+ days ago
            if let days = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day, days >= 2 {
                shouldRequest = true
            }
        }

        if shouldRequest {
            defaults.set(Date(), forKey: lastReviewRequestKey)
        }
        
        return shouldRequest
    }

    func requestReviewIfNeeded() {
        guard shouldRequestReview() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
