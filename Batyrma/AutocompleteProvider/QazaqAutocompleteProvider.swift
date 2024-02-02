//
//  QazaqAutocompleteProvider.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation
import KeyboardKit

class QazaqAutocompleteProvider: AutocompleteProvider {
    let suggestionEngine: WordSuggestionsEngine = QazaqWordSuggestionsEngine()

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
                suggestion.isAutocorrect = $0.isAutocorrect && context.isAutocorrectEnabled
                return suggestion
            }
    }
}

private extension QazaqAutocompleteProvider {
    func suggestions(for text: String) -> [Autocomplete.Suggestion] {
        var engineSuggestions = suggestionEngine.suggestWords(for: text)
            .filter { $0.similarity > 0.8 }
            .enumerated()
            .map { index, value in
                if index == 1 {
                    Autocomplete.Suggestion(text: value.word, subtitle: "Баскасы")
                } else {
                    Autocomplete.Suggestion(text: value.word, isAutocorrect: true)
                }
            }

        let plainText = Autocomplete.Suggestion(text: text, isUnknown: true)
        let suggestions = [plainText] + engineSuggestions

        return suggestions
    }
}
