//
//  AnalyticsEventProtocol.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 02.05.2024.
//

public struct CommonAnalyticsEvent: AnalyticsEventProtocol {
    public var name: String
    public var params: [String: Any]

    public init(name: String, params: [String : Any] = [:]) {
        self.name = name
        self.params = params
    }
}

public protocol AnalyticsEventProtocol {
    var name: String { get }
    var params: [String: Any] { get }
}
