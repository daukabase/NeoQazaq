//
//  AnalyticsService.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 02.05.2024.
//

// TODO: Move analytics into separate module

public protocol AnalyticsService {
    func track(event: AnalyticsEventProtocol)
}

public final class AnalyticsServiceFacade: AnalyticsService {
    public static let shared = AnalyticsServiceFacade()

    private let amplitudeService = AmplitudeAnalyticsService()
    private let firebaseService = FirebaseAnalyticsService()

    public func track(event: AnalyticsEventProtocol) {
        amplitudeService.track(event: event)
        firebaseService.track(event: event)
    }

    private func appendCommonParams(to params: [String: Any]) -> [String: Any] {
        var newParams = params
        newParams["timestamp"] = Date().timeIntervalSince1970
        newParams["version"] = GlobalConstants.appVersion
        return newParams
    }
}
