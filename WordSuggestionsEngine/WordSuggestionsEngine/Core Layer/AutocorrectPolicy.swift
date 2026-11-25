//
//  AutocorrectPolicy.swift
//  WordSuggestionsEngine
//
//  Decides, for each engine candidate, whether it may replace the typed word on space,
//  may only be offered in the suggestion bar, or must be hidden.
//
//  The old rule was "auto-replace anything scored above 0.95". It replaced ~300 correct
//  words (ол→өл, бар→бәр, сен→сең, туралы→тұралы) and Russian look-alikes (кит→қит).
//  The rule now is: never replace a real word unless it is on the reviewed allow-list.
//  See specs/01-fix-spec.md (C1) and specs/data/autocorrect-conflicts.tsv.
//

import Foundation

public struct AutocorrectPolicy {
    public enum Decision: Equatable {
        case autocorrect, suggest, hide
    }

    private let isKazakhWord: (String) -> Bool
    private let isRussianWord: (String) -> Bool
    private let allowList: Set<String>
    private let personal: PersonalStore?

    public init(
        isKazakhWord: @escaping (String) -> Bool,
        isRussianWord: @escaping (String) -> Bool,
        allowList: Set<String>,
        personal: PersonalStore?
    ) {
        self.isKazakhWord = isKazakhWord
        self.isRussianWord = isRussianWord
        self.allowList = allowList
        self.personal = personal
    }

    /// Policy backed by the bundled dictionaries. `extraRussianCheck` lets the keyboard add the
    /// system spell checker (UITextChecker), which knows far more Russian forms than the bundled list.
    public static func standard(
        personal: PersonalStore?,
        extraRussianCheck: ((String) -> Bool)? = nil
    ) -> AutocorrectPolicy {
        let loader = QazaqWordsDatasetLoader.shared
        return AutocorrectPolicy(
            isKazakhWord: { loader.containsKazakhWord($0) },
            isRussianWord: { word in loader.containsRussianWord(word) || (extraRussianCheck?(word) ?? false) },
            allowList: loader.autocorrectAllowList,
            personal: personal
        )
    }

    /// - Parameters:
    ///   - typed: the word as the user typed it (original casing).
    ///   - candidate: one engine candidate for that word.
    ///   - isSentenceStart: whether the word begins a sentence (so a capital letter is expected).
    public func decide(typed: String, candidate: GeneratedSimilarWord, isSentenceStart: Bool) -> Decision {
        let word = typed.lowercased()

        // Fragments that aren't words (канд → қанд), and single letters.
        if candidate.kind == .rootWithRawSuffix || word.count < 2 { return .hide }
        if let personal, personal.isIgnored(candidate.word) { return .hide }

        // The user kept this word before, or undid this exact correction.
        if let personal, personal.isLearned(word) || personal.isRejected(typed: word, candidate: candidate.word) {
            return .suggest
        }

        // A capital letter mid-sentence is probably a name (Куаныш, Жанар): never replace it.
        if typed.first?.isUppercase == true && !isSentenceStart { return .suggest }

        // Reviewed misspellings that slipped into the word list (жаксы, орталык, казак…).
        if allowList.contains(word) {
            return candidate.kind == .dictionaryWord ? .suggest : .autocorrect
        }

        // Never replace a real Kazakh or Russian word.
        if isKazakhWord(word) || isRussianWord(word) { return .suggest }

        switch candidate.kind {
        case .dictionaryWord, .endingOnlyChange:
            // Nothing was restored in the root, or only the ending changed (барамын → барамың).
            return .suggest
        case .exactKey, .alteredRoot, .rootWithGeneratedEnding:
            // Keep "> 0.95": a score of exactly 0.95 marks entries that must never auto-apply
            // (vulgar words, казак) — see specs/01-fix-spec.md §0.1.
            return candidate.similarity > 0.95 ? .autocorrect : .suggest
        case .rootWithRawSuffix:
            return .hide
        }
    }
}
