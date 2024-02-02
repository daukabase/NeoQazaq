//
//  WordSuggestionsEngine.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation

struct GeneratedSimilarWord {
    let word: String
    // from 0 to 1
    let similarity: Double
}

protocol WordSuggestionsEngine {
    func suggestWords(for text: String) -> [GeneratedSimilarWord]
}

class QazaqWordSuggestionsEngine: WordSuggestionsEngine {
    func suggestWords(for text: String) -> [GeneratedSimilarWord] {
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

