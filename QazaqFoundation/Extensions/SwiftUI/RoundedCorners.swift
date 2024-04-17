//
//  RoundedCorners.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 17.04.2024.
//

import SwiftUI

public extension View {
    func roundCorners(value: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerSize: CGSize(width: value, height: value)))
    }
}
