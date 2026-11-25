//
//  WordSuggestionsEngine.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation

/// Where a candidate came from. `AutocorrectPolicy` uses this to decide whether the
/// candidate may replace the typed word, may only be suggested, or must be hidden.
public enum MatchKind: Equatable, Sendable {
    /// The whole typed word is a key in the typed→proper-Kazakh map.
    case exactKey
    /// The whole typed word matched after reversing a final consonant change (ғ→қ, б→п, г→к).
    case alteredRoot
    /// The start of the word matched and the ending was rebuilt, with the root itself restored
    /// (e.g. казагым → қазағым).
    case rootWithGeneratedEnding
    /// The start of the word matched and was already correct; only the ending was changed.
    /// Ambiguous: барамын ("I'm going") would become the possessive барамың.
    case endingOnlyChange
    /// The start matched but the ending could not be rebuilt, so the raw typed ending was glued on.
    /// Produces fragments that aren't words (канд → қанд).
    case rootWithRawSuffix
    /// The typed word (or its start) is itself in the Kazakh or Russian word list.
    case dictionaryWord
}

public struct GeneratedSimilarWord: Equatable {
    public let word: String
    // from 0 to 1
    public let similarity: Double
    public let kind: MatchKind

    public init(word: String, similarity: Double, kind: MatchKind) {
        self.word = word
        self.similarity = similarity
        self.kind = kind
    }
}

public protocol WordSuggestionsEngine {
    func suggestWords(for text: String) -> [GeneratedSimilarWord]
}

public final class QazaqWordSuggestionsEngineV2: WordSuggestionsEngine {
    private let qazaqWordsDatasetLoader = QazaqWordsDatasetLoader.shared

    enum Source: Equatable {
        case shalaMap, alteredRoot, kazakhWord, russianWord
    }

    struct Match {
        let variations: [SuggestionVariation]
        /// The typed prefix that matched (may be shorter than the typed word).
        let root: String
        let source: Source
    }

    public init() {}

    public func suggestWords(for text: String) -> [GeneratedSimilarWord] {
        guard let match = findRootVariationsFromDatabase(for: text) else {
            return []
        }
        let isFullMatch = match.root.count == text.count

        return match.variations
            .sorted(by: { $0.percentage > $1.percentage })
            .map { variation -> GeneratedSimilarWord in
                var percentage = variation.percentage
                var isFragment = false

                let word: String
                if let suffix = suffix(for: text, root: variation.taza) {
                    let generator = QazaqEndingsGenerator()
                    if let correctedEnding = generator.generateTazaOutput(for: text, root: variation.taza) {
                        word = correctedEnding
                        // The generator may have matched all but the last letter and glued it back on.
                        isFragment = !isFullMatch
                            && generator.generateTazaOutputMatchingWholeInput(for: text, root: variation.taza) == nil
                    } else {
                        percentage = 0.9
                        word = variation.taza + suffix
                        isFragment = !isFullMatch
                    }
                } else {
                    word = variation.taza
                }

                let kind: MatchKind
                if isFragment {
                    kind = .rootWithRawSuffix
                } else if isFullMatch {
                    switch match.source {
                    case .shalaMap: kind = .exactKey
                    case .alteredRoot: kind = .alteredRoot
                    case .kazakhWord, .russianWord: kind = .dictionaryWord
                    }
                } else if match.source == .kazakhWord || match.source == .russianWord || variation.taza == match.root {
                    // The matched start was already a correct word; only the ending changed.
                    kind = .endingOnlyChange
                } else {
                    kind = .rootWithGeneratedEnding
                }
                return GeneratedSimilarWord(word: word, similarity: percentage, kind: kind)
            }
            .filter { $0.word != text }
    }

    func findRootVariationsFromDatabase(for text: String) -> Match? {
        var count = text.count

        while count > 1 {
            let targetRoot = text[0 ..< count]
            if let match = findVariations(for: targetRoot) {
                return match
            }
            count = count - 1
        }

        return nil
    }

    func findVariations(for targetRoot: String) -> Match? {
        if let variations = qazaqWordsDatasetLoader.variations(for: targetRoot) {
            return Match(variations: variations, root: targetRoot, source: .shalaMap)
        } else if let alteredVariations = findAlteredRoot(for: targetRoot) {
            return Match(variations: alteredVariations, root: targetRoot, source: .alteredRoot)
        } else if qazaqWordsDatasetLoader.containsKazakhWord(targetRoot) {
            return Match(variations: [SuggestionVariation(taza: targetRoot, percentage: 1)], root: targetRoot, source: .kazakhWord)
        } else if qazaqWordsDatasetLoader.containsRussianWord(targetRoot) {
            return Match(variations: [SuggestionVariation(taza: targetRoot, percentage: 0.9)], root: targetRoot, source: .russianWord)
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
        return qazaqWordsDatasetLoader.variations(for: alteredRoot)
    }

    func suffix(for text: String, root: String) -> String? {
        let hasSuffixes = root.count <= text.count
        let suffix = hasSuffixes ? text[root.count ..< text.count] : nil
        return suffix
    }
}
