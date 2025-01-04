//
//  AnalyticsService.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 02.05.2024.
//

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

    public func track(event: AnalyticsEventProtocol) {
        queue.async {
            self.amplitudeService.track(event: event)
            print("[Analytics] event: \(event.name), params: \(event.params)")
        }
    } 

    private func appendCommonParams(to params: [String: Any]) -> [String: Any] {
        var newParams = params
        newParams["timestamp"] = Date().timeIntervalSince1970
        newParams["version"] = GlobalConstants.appVersion
        return newParams
    }
}
