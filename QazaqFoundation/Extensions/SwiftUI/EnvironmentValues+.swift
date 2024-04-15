//
//  EnvironmentValues+.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 15.04.2024.
//

import SwiftUI

extension EnvironmentValues {
    public var isDarkMode: Bool {
        self.colorScheme == .dark
    }
}
