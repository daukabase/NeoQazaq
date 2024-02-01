//
//  UIStackView+.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import UIKit

extension UIStackView {
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
            NSLayoutConstraint.deactivate($0.constraints)
        }
    }
}
