//
//  AnalyticsService.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 02.05.2024.
//

import FirebaseCore

public protocol AnalyticsService {
    func track(event: AnalyticsEventProtocol)
}

public final class AnalyticsServiceFacade: AnalyticsService {
    public static let shared = AnalyticsServiceFacade()
    private let queue: DispatchQueue

    init() {
        self.queue = DispatchQueue(label: "com.qazaq-foundation.analytics", qos: .background, attributes: .concurrent)
    }

    private let amplitudeService = AmplitudeAnalyticsService()
    private let firebaseService = FirebaseAnalyticsService()
    
    public func configure() {
        queue.async {
            FirebaseApp.configure()
        }
    }

    public func track(event: AnalyticsEventProtocol) {
        queue.async {
            self.amplitudeService.track(event: event)
            self.firebaseService.track(event: event)
        }
    }

    private func appendCommonParams(to params: [String: Any]) -> [String: Any] {
        var newParams = params
        newParams["timestamp"] = Date().timeIntervalSince1970
        newParams["version"] = GlobalConstants.appVersion
        return newParams
    }
}
