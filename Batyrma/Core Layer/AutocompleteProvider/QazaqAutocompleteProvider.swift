//
//  QazaqAutocompleteProvider.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation
import KeyboardKit

class QazaqAutocompleteProvider: AutocompleteProvider {
    let suggestionEngine: WordSuggestionsEngine = QazaqWordSuggestionsEngineV2()
    @UserDefault("isAutocompleteEnabled", store: .localAppGroup)
    var isAutocompleteEnabled: Bool = false

    init(context: AutocompleteContext) {
        self.context = context
    }

    private var context: AutocompleteContext
    
    var locale: Locale = .current
    
    var canIgnoreWords: Bool { false }
    var canLearnWords: Bool { false }
    var ignoredWords: [String] = []
    var learnedWords: [String] = []
    
    func hasIgnoredWord(_ word: String) -> Bool { false }
    func hasLearnedWord(_ word: String) -> Bool { false }
    func ignoreWord(_ word: String) {}
    func learnWord(_ word: String) {}
    func removeIgnoredWord(_ word: String) {}
    func unlearnWord(_ word: String) {}
    
    func autocompleteSuggestions(
        for text: String
    ) async throws -> [Autocomplete.Suggestion] {
        guard text.count > 0 else { return [] }
        return suggestions(for: text)
            .map {
                var suggestion = $0
                suggestion.isAutocorrect = $0.isAutocorrect && context.isAutocorrectEnabled && isAutocompleteEnabled
                return suggestion
            }
    }
}

private extension QazaqAutocompleteProvider {
    func suggestions(for text: String) -> [Autocomplete.Suggestion] {
        let lowercased = text.lowercased()
        let uppercasedIndices = uppercasedCharactersIndices(of: text)
        let engineSuggestions = suggestionEngine.suggestWords(for: lowercased)
            .enumerated()
            .map { index, value in
                // If user typed in uppercase, we should return suggestions in uppercase
                let word = uppercaseLettersOfTextFor(uppercasedIndices: uppercasedIndices, text: value.word)
                return Autocomplete.Suggestion(text: word, isAutocorrect: value.similarity > 0.95)
            }

        let plainText = Autocomplete.Suggestion(text: text, isUnknown: true)
        let suggestions = [plainText] + engineSuggestions

        return suggestions
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
