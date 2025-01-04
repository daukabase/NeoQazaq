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

class QazaqAutocompleteProvider: AutocompleteService {
    private let suggestionEngine: WordSuggestionsEngine = QazaqWordSuggestionsEngineV2()

    @UserDefault(item: UserDefaults.autocompleteItem)
    private var isAutocompleteEnabled
    
    init(context: AutocompleteContext) {
        self.context = context
    }
    
    private var context: AutocompleteContext

    // MARK: - AutocompleteService

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

    func autocomplete(_ text: String) async throws -> Autocomplete.ServiceResult {
        let lastWord = text.components(separatedBy: .whitespaces).last ?? ""
        return Autocomplete.ServiceResult(inputText: lastWord, suggestions: getAutocompleteSuggestions(for: lastWord))
    }

    private func getAutocompleteSuggestions(
        for text: String
    ) -> [Autocomplete.Suggestion] {
        guard text.count > 0 else { return [] }
        return suggestions(for: text)
    }
}

private extension QazaqAutocompleteProvider {
    func suggestions(for text: String) -> [Autocomplete.Suggestion] {
        let lowercased = text.lowercased()
        let uppercasedIndices = uppercasedCharactersIndices(of: text)
        let engineSuggestions = suggestionEngine.suggestWords(for: lowercased)
            .sorted(by: { $0.similarity > $1.similarity })
            .map { value in
                let word = uppercaseLettersOfTextFor(uppercasedIndices: uppercasedIndices, text: value.word)
                let isAutocorrect = value.similarity > 0.95 && isAutocompleteEnabled == true
                return Autocomplete.Suggestion(text: word, type: isAutocorrect ? .autocorrect : .unknown)
            }
            .prefix(2)

        let plainText = Autocomplete.Suggestion(text: text, type: .unknown)
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
