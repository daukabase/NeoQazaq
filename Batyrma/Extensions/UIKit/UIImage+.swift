//
//  UIImage+.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize, with renderingMode: RenderingMode) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(renderingMode)
    }
}
