//
//  FirebaseAnalyticsService.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 02.05.2024.
//

import FirebaseAnalytics

internal final class FirebaseAnalyticsService: AnalyticsService {
    internal func track(event: AnalyticsEventProtocol) {
        Analytics.logEvent(event.name, parameters: event.params)
    }
}

