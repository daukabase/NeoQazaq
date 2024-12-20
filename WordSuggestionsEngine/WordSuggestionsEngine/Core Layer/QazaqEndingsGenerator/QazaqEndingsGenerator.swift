//
//  QazaqEndingsGenerator.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 14.02.2024.
//

import QazaqFoundation

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

    func generateTazaOutput(for input: String, root: String) -> String? {
        let shalaDataset = generateShalaqazaqDatasetForEndings(for: root)

        for i in (input.count - 1 ..< input.count + 1).reversed() {
            let subString = input[0..<i]
            if let taza = shalaDataset[subString] {
                let suffix = suffix(for: input, root: subString) ?? ""
                return taza + suffix
            }
        }

        return nil
    }

    func suffix(for text: String, root: String) -> String? {
        let hasSuffixes = root.count <= text.count
        let suffix = hasSuffixes ? text[root.count ..< text.count] : nil
        return suffix
    }

    /// Make dataset for shalaqazaq ending for root
    /// For example, for input "озеннин" clean kazakh root is "өзен"
    /// This algorithm will generate all possible endings for word "өзен"
    /// Then convert unique kazakh words to russian shala variants
    /// Final dataset gonna be like that:
    /// [
    /// "озенде": "өзен",
    /// "озеннин": "өзеннің"
    /// "озеним": "өзенім",
    /// ...
    /// ]
    func generateShalaqazaqDatasetForEndings(for root: String) -> [String: String] {
        var shalaqazaqDataset: [String: String] = [:]
        generateEndings(for: root).forEach { wordWithEnding in
            let shalaEndings = generateShalaWords(for: wordWithEnding, targetShala: "", currentIndex: 0)
            shalaEndings.forEach { shalaEnding in
                shalaqazaqDataset[shalaEnding] = wordWithEnding
            }
        }
        return shalaqazaqDataset
    }

    // backtracking like approach
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
