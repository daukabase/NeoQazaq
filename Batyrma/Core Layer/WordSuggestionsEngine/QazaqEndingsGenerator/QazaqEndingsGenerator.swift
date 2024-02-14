//
//  QazaqEndingsGenerator.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 14.02.2024.
//

import Foundation

enum Form: CaseIterable {
    case first, second, secondRespectful, third
}

enum Quantity: CaseIterable {
    case singular, plural
}

protocol Service {
    func process(text: String) -> String
}

struct QazaqEndingsGenerator {
    
    let qazToShala: [String: [String]] = [
        "ә": ["а"],
        "ғ": ["г"],
        "қ": ["к"],
        "ң": ["н"],
        "ө": ["о"],
        "ұ": ["у"],
        "ү": ["у"],
        "һ": ["х"],
        "і": ["и", "ы"]
    ]

    init() {}

    func generateEndings(for word: String) -> [String] {
        return Form.allCases.map { form in
            let posessives = Quantity.allCases.map { quantity in
                let service = PossessiveService(possessive: form, quantitative: quantity)
                return service.process(text: word)
            }

            let quantitatives = Quantity.allCases.map { quantity in
                let service = QuantitativeService(quantitative: quantity)
                return service.process(text: word)
            }
            return posessives + quantitatives
        }.flatMap { $0 }
    }

    // TODO: generate data for cases with
    // endings like "қазақ" and "қазағым"

    /// if user typed "казагым" input root must be "қазақ" not "қазағ"
    func generateShalaqazaqDatasetForEndings(for root: String) -> [String: String] {
        var shalaqazaqDataset: [String: String] = [:]
        generateEndings(for: root)
            .forEach { wordWithEnding in
                let shalaEndigns = generateShalaWords(for: wordWithEnding, targetShala: "", currentIndex: 0)
                shalaEndigns.forEach { shalaEnding in
                    shalaqazaqDataset[shalaEnding] = wordWithEnding
                }
            }
        return shalaqazaqDataset
    }

    private func generateShalaWords(for word: String, targetShala: String, currentIndex: Int) -> [String] {
        var targetShala = targetShala
        for index in (currentIndex ..< word.count) {
            let letter = String(word[index])
            guard let shalaLetters = qazToShala[letter] else {
                targetShala.append(letter)
                continue
            }
            var shalaWords = [String]()
            shalaLetters.forEach { shalaLetter in
                targetShala.append(shalaLetter)
                let generatedShala = generateShalaWords(for: word, targetShala: targetShala, currentIndex: index + 1)
                targetShala.removeLast()
                shalaWords.append(contentsOf: generatedShala)
            }
            return shalaWords
        }
        return [targetShala]
    }

}
