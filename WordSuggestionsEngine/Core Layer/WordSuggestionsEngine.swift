//
//  WordSuggestionsEngine.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation

public struct GeneratedSimilarWord {
    let word: String
    // from 0 to 1
    let similarity: Double
}

public protocol WordSuggestionsEngine {
    func suggestWords(for text: String) -> [GeneratedSimilarWord]
}

public final class QazaqWordSuggestionsEngineV2: WordSuggestionsEngine {
    private let qazaqWordsDatasetLoader = QazaqWordsDatasetLoader.shared

    public init() {}

    public func suggestWords(for text: String) -> [GeneratedSimilarWord] {
        guard let variations = findRootVariationsFromDatabase(for: text) else {
            return []
        }

        return variations
            .sorted(by: { $0.percentage > $1.percentage })
            .map { variation -> GeneratedSimilarWord in
                let word = {
                    guard let suffix = suffix(for: text, root: variation.taza) else {
                        return variation.taza
                    }

                    guard let correctedEnding = QazaqEndingsGenerator().generateTazaOutput(
                        for: text,
                        root: variation.taza
                    ) else {
                        return variation.taza + suffix
                    }

                    return correctedEnding
                }()
                return GeneratedSimilarWord(word: word, similarity: variation.percentage)
            }
    }

    func findRootVariationsFromDatabase(for text: String) -> [SuggestionVariation]? {
        var count = text.count

        while count > 1 {
            let targetRoot = text[0 ..< count]
            if let variations = findVariations(for: targetRoot) {
                return variations
            }
            count = count - 1
        }

        return nil
    }

    func findVariations(for targetRoot: String) -> [SuggestionVariation]? {
        if let variations = qazaqWordsDatasetLoader.shalaqazaqVariations()[targetRoot], !variations.isEmpty {
            return variations
        } else if let alteredVariations = findAlteredRoot(for: targetRoot) {
            return alteredVariations
        } else if let qazaqWord = findIfQazaqWordsContains(targetRoot: targetRoot) {
            return [SuggestionVariation(taza: qazaqWord, percentage: 1)]
        }
        return nil
    }

    func findAlteredRoot(for targetRoot: String) -> [SuggestionVariation]? {
        guard
            let last = targetRoot.last,
            let altered = PossessiveService.Constants.consonantAlterationReversed[String(last)]
        else {
            return nil
        }

        let alteredRoot = String(targetRoot.dropLast() + altered)

        guard let variations = qazaqWordsDatasetLoader.shalaqazaqVariations()[alteredRoot], !variations.isEmpty else {
            return nil
        }

        return variations
    }

    func findIfQazaqWordsContains(targetRoot: String) -> String? {
        if qazaqWordsDatasetLoader.qazaqWordsList().contains(targetRoot) {
            return targetRoot
        }
        return nil
    }

    func suffix(for text: String, root: String) -> String? {
        let hasSuffixes = root.count <= text.count
        let suffix = hasSuffixes ? text[root.count ..< text.count] : nil
        return suffix
    }

}

