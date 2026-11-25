//
//  AmplitudeAnalyticsService.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 02.05.2024.
//

import AmplitudeSwift
import Foundation

internal final class AmplitudeAnalyticsService: AnalyticsService {
    private let amplitude: Amplitude

    init() {
        amplitude = Amplitude(configuration: Configuration(
            apiKey: "976f49b1ad18b56e1dd445ae97355e70"
        ))
        shareDeviceIdWithKeyboard()
    }

    internal func track(event: AnalyticsEventProtocol) {
        amplitude.track(eventType: event.name, eventProperties: event.params)
    }

    /// The app and the keyboard are separate processes with separate Amplitude storage, so by
    /// default Amplitude counts them as two users and app→keyboard funnels don't connect.
    /// The app publishes its device ID in the app group; the keyboard reads it (reading the
    /// app group works even without Full Access) and reports under the same ID.
    private func shareDeviceIdWithKeyboard() {
        let shared = UserDefaults.localAppGroup
        let key = UserDefaults.sharedAnalyticsDeviceIdKey
        let isAppExtension = Bundle.main.bundlePath.hasSuffix(".appex")

        if isAppExtension {
            if let appDeviceId = shared.string(forKey: key), appDeviceId != amplitude.getDeviceId() {
                amplitude.setDeviceId(deviceId: appDeviceId)
            }
        } else if let deviceId = amplitude.getDeviceId(), shared.string(forKey: key) != deviceId {
            shared.set(deviceId, forKey: key)
        }
    }
}
