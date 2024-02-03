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


// канагат тан дыр ыл ма ган дык тар ын ыз дан
//

// zatEsim (possible tail change к -> г) + <septik>

func datasetFileURL() -> [String: String]{
    if let fileURL = Bundle.main.url(forResource: "ShalaqazaqDataset", withExtension: "json") {
        do {
            // Read the file content
            let data = try Data(contentsOf: fileURL)
            
            // Decode the JSON data
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([String: String].self, from: data)
            
            return jsonData
        } catch {
            // Handle errors
            print("Error reading or parsing the JSON file: \(error.localizedDescription)")
        }
    } else {
        print("JSON file not found in playground resources.")
    }
    return [:]
}

class QazaqWordSuggestionsEngine: WordSuggestionsEngine {
    static let dataset: [String: String] = {
        let decoder = JSONDecoder()
        guard
            let fileURL = Bundle.main.url(forResource: "ShalaqazaqDataset", withExtension: "json"),
            let data = try? Data(contentsOf: fileURL),
            let jsonData = try? decoder.decode([String: String].self, from: data)
        else {
            fatalError()
        }

        return jsonData
    }()

    func suggestWords(for text: String) -> [GeneratedSimilarWord] {
        let word = QazaqWordSuggestionsEngine.dataset[text].map {
            GeneratedSimilarWord(word: $0, similarity: 1)
        }
        return [word].compactMap { $0 }
    }
}

