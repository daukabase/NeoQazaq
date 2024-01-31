//
//  QazaqAutocompleteProvider.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 31.01.2024.
//

import Foundation

struct Autocomplete {
    struct Suggestion {
        var text: String
        var subtitle: String?
        var isUnknown = false
        var isAutocorrect = false
    }
}

/**
 This fake autocomplete provider is used in the non-pro demo,
 to show fake suggestions while typing.
 */
protocol AutocompleteProvider {
    func autocompleteSuggestions(
        for text: String
    ) async throws -> [Autocomplete.Suggestion]
}

class QazaqAutocompleteProvider: AutocompleteProvider {

    init() {}

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
        return fakeSuggestions(for: text)
            .map {
                var suggestion = $0
                suggestion.isAutocorrect = $0.isAutocorrect
                return suggestion
            }
    }
}

private extension QazaqAutocompleteProvider {
    func fakeSuggestions(for text: String) -> [Autocomplete.Suggestion] {
        [
            .init(text: text, isUnknown: true),
            .init(text: similarWords(for: text).first!, isAutocorrect: true),
            .init(text: text, subtitle: "Subtitle")
        ]
    }

    func similarWords(for text: String) -> [String] {
        if text == "ozen" {
            return ["өзен"]
        } else if text == "жумыс" {
            return ["жұмыс"]
        } else if text == "jumys" {
            return ["жұмыс"]
        } else if text == "ozende" {
            return ["өзенде"]
        } else if text == "boldi" {
            return ["болды"]
        } else if text == "men" {
            return ["мен"]
        } else {
            return [text]
        }
    }
}
