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


typealias ShalaVariation = QazaqWordSuggestionsEngineV2.ShalaVariation

class QazaqWordSuggestionsEngineV2: WordSuggestionsEngine {
    struct ShalaVariation: Codable {
        let taza: String
        let percentage: Double
    }

    static let dataset: [String: [ShalaVariation]] = {
        let decoder = JSONDecoder()
        guard
            let fileURL = Bundle.main.url(forResource: "ShalaqazaqDatasetV2", withExtension: "json"),
            let data = try? Data(contentsOf: fileURL),
            let jsonData = try? decoder.decode([String: [String: Double]].self, from: data)
        else {
            fatalError()
        }

        return jsonData.mapValues { rawVariations -> [ShalaVariation] in
            rawVariations.map { (key, value) in
                ShalaVariation(taza: key, percentage: value)
            }
        }
    }()
    
    func suggestWords(for text: String) -> [GeneratedSimilarWord] {
        guard let variations = findRootVariationsFromDatabase(for: text) else {
            return []
        }

        return variations
            .sorted(by: { $0.percentage > $1.percentage })
            .map { variation -> GeneratedSimilarWord in
                let word = {
                    if let suffix = suffix(for: text, root: variation.taza) {
                        return variation.taza + suffix
                    }
                    return variation.taza
                }()
                return GeneratedSimilarWord(word: word, similarity: variation.percentage)
            }
    }

    func findRootVariationsFromDatabase(for text: String) -> [ShalaVariation]? {
        var count = text.count

        while count > 1 {
            let targetRoot = text[0 ..< count]
            let variations = Self.dataset[targetRoot]
            
            if let variations, !variations.isEmpty {
                return variations
            }

            count = count - 1
        }

        return nil
    }
    
    func suffix(for text: String, root: String) -> String? {
        let hasSuffixes = root.count <= text.count
        let suffix = hasSuffixes ? text[root.count ..< text.count] : nil
        return suffix
    }

}

