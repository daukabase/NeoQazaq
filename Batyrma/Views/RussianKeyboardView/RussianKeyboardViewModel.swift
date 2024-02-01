//
//  RussianKeyboardViewModel.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import UIKit

struct RussianKeyboardViewModel {
    enum Constants {
        static let russianKeys = {
            russianUppercasedKeys.map { row in
                row.map { key in
                    LetterKey(uppercased: key, lowercased: key.lowercased())
                }
            }
        }()
        static let russianUppercasedKeys = [
            ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х"],
            ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э"],
            // TODO: добавить твердый знак
            ["Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю"]
        ]
    }

    var shift: Shift = .lowercased
    let letterKeys: [[LetterKey]] = Constants.russianKeys
}

enum Shift: Equatable {
    case lowercased
    case uppercasedOnce
    case uppercased

    var next: Shift {
        switch self {
        case .lowercased:
            return .uppercasedOnce
        case .uppercasedOnce:
            return .lowercased
        case .uppercased:
            return .lowercased
        }
    }

    var image: UIImage? {
        switch self {
        case .lowercased:
            return Shift.resizedLowercasedImage
        case .uppercased:
            return Asset.Images.keyUppercased.image
        case .uppercasedOnce:
            return Asset.Images.keyUppercasedOnce.image
        }
    }

    private static let resizedLowercasedImage = Asset.Images.keyLowercased.image
        .resized(
            to: CGSize(width: 28, height: 28),
            with: .alwaysOriginal
        )
}
