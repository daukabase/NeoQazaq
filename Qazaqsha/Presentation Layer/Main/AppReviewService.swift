//
//  AppReviewService.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 12.12.2024.
//

import QazaqFoundation
import StoreKit

final class AppReviewService {
    enum Constants {
        static let lastReviewRequestKey = "lastReviewRequest"
        static let appLaunchCountKey = "appLaunchCount"
    }

    static let shared = AppReviewService()

    private let defaults = UserDefaults.standard

    @UserDefault(wrappedValue: 0, Constants.appLaunchCountKey)
    private var appLaunchCountKey: Int

    @UserDefault(Constants.lastReviewRequestKey)
    private var lastReviewDate: Date?

    private init() {}

    func shouldRequestReview() -> Bool {
        appLaunchCountKey += 1

        let launchCount = appLaunchCountKey
        let lastRequest = lastReviewDate

        var shouldRequest = false
        if launchCount > 2 {
            shouldRequest = true
            appLaunchCountKey = 0
        } else if let lastRequest {
            let daysFromLastRequest = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
            if daysFromLastRequest >= 5 {
                shouldRequest = true
            }
        }

        if shouldRequest {
            lastReviewDate = Date()
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
