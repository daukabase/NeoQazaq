//
//  QazaqAutocompleteProvider.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation
import KeyboardKit
import QazaqFoundation
import WordSuggestionsEngine

/// Builds the suggestion bar: the word as typed first, then up to two engine candidates.
/// `AutocorrectPolicy` decides which candidate (if any) may replace the typed word on space,
/// so correct Kazakh and Russian words are no longer "fixed" (specs/01-fix-spec.md C1–C4).
final class QazaqAutocompleteProvider: AutocompleteService {
    private let suggestionEngine: WordSuggestionsEngine = QazaqWordSuggestionsEngineV2()
    private let predictive = PredictiveText.shared
    private let store: PersonalStore
    private let policy: AutocorrectPolicy

    /// The "Magic Auto-Correction" switch in the app. When off, candidates are still shown
    /// but never applied automatically.
    @UserDefault(item: UserDefaults.autocompleteItem)
    private var isAutocompleteEnabled

    init(store: PersonalStore, russianSpellChecker: RussianSpellChecker) {
        self.store = store
        self.policy = .standard(personal: store, extraRussianCheck: { russianSpellChecker.isValidWord($0) })
    }

    // MARK: - AutocompleteService

    var locale: Locale = .current

    var canIgnoreWords: Bool { true }
    var canLearnWords: Bool { true }
    var ignoredWords: [String] { store.ignoredWords }
    var learnedWords: [String] { store.learnedWords }

    func hasIgnoredWord(_ word: String) -> Bool { store.isIgnored(word) }
    func hasLearnedWord(_ word: String) -> Bool { store.isLearned(word) }
    func ignoreWord(_ word: String) { store.ignore(word) }
    func learnWord(_ word: String) { store.learn(word) }
    func removeIgnoredWord(_ word: String) { store.removeIgnored(word) }
    func unlearnWord(_ word: String) { store.unlearn(word) }

    func autocomplete(_ text: String) async throws -> Autocomplete.ServiceResult {
        let context = TypingContext(text: text)
        let suggestions = context.word.isEmpty
            ? nextWordSuggestions(after: context.previousWord, isSentenceStart: context.isSentenceStart, text: text)
            : suggestions(for: context.word, isSentenceStart: context.isSentenceStart)
        return Autocomplete.ServiceResult(inputText: context.word, suggestions: suggestions)
    }
}

private extension QazaqAutocompleteProvider {
    /// While typing: [as typed] [autocorrection, if any] [most frequent completions/alternatives].
    func suggestions(for word: String, isSentenceStart: Bool) -> [Autocomplete.Suggestion] {
        let maxCandidates = 2
        let uppercasedIndices = uppercasedCharactersIndices(of: word)
        let lowercasedWord = word.lowercased()
        var autocorrection: Autocomplete.Suggestion?
        var ranked: [(text: String, score: Int)] = []

        func isNew(_ text: String) -> Bool {
            text.lowercased() != lowercasedWord
                && autocorrection?.text.lowercased() != text.lowercased()
                && !ranked.contains { $0.text.lowercased() == text.lowercased() }
        }

        // 1. Letter restoration / corrections from the engine, filtered by the autocorrect rules.
        if word.count > 1 {
            for candidate in suggestionEngine.suggestWords(for: lowercasedWord).sorted(by: { $0.similarity > $1.similarity }) {
                let decision = policy.decide(typed: word, candidate: candidate, isSentenceStart: isSentenceStart)
                guard decision != .hide else { continue }
                let text = uppercaseLettersOfTextFor(uppercasedIndices: uppercasedIndices, text: candidate.word)
                guard isNew(text) else { continue }
                if decision == .autocorrect && isAutocompleteEnabled && autocorrection == nil {
                    autocorrection = Autocomplete.Suggestion(text: text, type: .autocorrect)
                } else {
                    ranked.append((text, predictive.score(of: candidate.word) ?? 0))
                }
            }
        }

        // 2. Completions of the current word in Kazakh and Russian, ranked by frequency.
        for prediction in predictive.completions(for: word, limit: 4) {
            let text = uppercaseLettersOfTextFor(uppercasedIndices: uppercasedIndices, text: prediction.word)
            if isNew(text) { ranked.append((text, prediction.score)) }
        }

        let remaining = maxCandidates - (autocorrection == nil ? 0 : 1)
        let alternatives = ranked
            .sorted { $0.score > $1.score }
            .prefix(remaining)
            .map { Autocomplete.Suggestion(text: $0.text, type: .regular) }

        // The typed word is `.unknown`: tapping it keeps it and (with autolearn on) teaches the keyboard.
        return [Autocomplete.Suggestion(text: word, type: .unknown)] + [autocorrection].compactMap { $0 } + alternatives
    }

    /// After a space: the likeliest next words. At a sentence start, likely first words, capitalised.
    func nextWordSuggestions(after previousWord: String?, isSentenceStart: Bool, text: String) -> [Autocomplete.Suggestion] {
        guard !text.isEmpty else { return [] }  // empty field: nothing to predict from yet
        let language = PredictiveText.language(of: String(text.suffix(200)))
        return predictive.nextWords(after: isSentenceStart ? nil : previousWord, language: language, limit: 3).map { word in
            let display = isSentenceStart ? word.prefix(1).uppercased() + word.dropFirst() : word
            return Autocomplete.Suggestion(text: display, type: .regular)
        }
    }

    func uppercasedCharactersIndices(of text: String) -> Set<Int> {
        Set(text.enumerated().compactMap { index, character in
            character.isUppercase ? index : nil
        })
    }

    func uppercaseLettersOfTextFor(uppercasedIndices: Set<Int>, text: String) -> String {
        text.enumerated().map { (index, value) in
            if uppercasedIndices.contains(index) {
                return value.uppercased()
            }
            return value.lowercased()
        }.joined()
    }
}
