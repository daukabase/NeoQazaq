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

func datasetFileURL() -> [String: String] {
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
        guard let (root, suffix) = findRootAndSuffix(for: text) else {
            return []
        }
        
        if let suffix {
            return [
                GeneratedSimilarWord(word: root + suffix, similarity: 0.9),
                GeneratedSimilarWord(word: root, similarity: 0.9)
            ]
        } else {
            return [GeneratedSimilarWord(word: root, similarity: 1.0)]
        }
    }

    func findRootAndSuffix(for text: String) -> (String, String?)? {
        guard let root = findRootFromDatabase(for: text) else {
            return nil
        }

        let hasSuffixes = root.count <= text.count
        let suffix = hasSuffixes ? text[root.count ..< text.count] : nil
        return (root, suffix)
    }

    func findRootFromDatabase(for text: String) -> String? {
        var count = text.count
        
        while count > 1 {
            let targetRoot = text[0 ..< count]
            if let root = QazaqWordSuggestionsEngine.dataset[targetRoot] {
                return root
            }
            count = count - 1
        }

        return nil
    }
}

