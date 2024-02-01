//
//  QazaqAutocompleteProvider.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation

struct Suggestion {
    var isAutocorrectionEnabled = false
    var text: String
}

struct GeneratedSimilarWord {
    let word: String
    // from 0 to 1
    let similarity: Double
}

class QazaqAutocompleteProvider: AutocompleteProvider {
    var isAutocorrectEnabled = true

    func suggestions(for text: String) -> [Suggestion] {
        generateSimilarWords(for: text)
            .filter { $0.similarity > 0.8 }
            .map {
                Suggestion(isAutocorrectionEnabled: isAutocorrectEnabled, text: $0.word)
            }
    }

    private func generateSimilarWords(for text: String) -> [GeneratedSimilarWord] {
        if text == "озен" {
            return [GeneratedSimilarWord(word: "өзен", similarity: 1)]
        } else if text == "жумыс" {
            return [GeneratedSimilarWord(word: "жұмыс", similarity: 1)]
        } else if text == "jumys" {
            return [GeneratedSimilarWord(word: "жұмыс", similarity: 1)]
        } else if text == "озенде" {
            return [GeneratedSimilarWord(word: "өзенде", similarity: 1)]
        } else {
            return []
        }
    }
}
