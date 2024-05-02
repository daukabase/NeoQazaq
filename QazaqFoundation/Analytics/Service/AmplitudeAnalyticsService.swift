//
//  AmplitudeAnalyticsService.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 02.05.2024.
//

import AmplitudeSwift

internal final class AmplitudeAnalyticsService: AnalyticsService {
    private let amplitude = Amplitude(configuration: Configuration(
        apiKey: "976f49b1ad18b56e1dd445ae97355e70"
    ))

    internal func track(event: AnalyticsEventProtocol) {
        amplitude.track(eventType: event.name, eventProperties: event.params)
    }
}
