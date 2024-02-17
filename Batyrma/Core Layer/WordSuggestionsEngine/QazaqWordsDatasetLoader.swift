//
//  QazaqWordsDatasetLoader.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 17.02.2024.
//

import Foundation

struct SuggestionVariation: Codable {
    let taza: String
    let percentage: Double
}

final class QazaqWordsDatasetLoader {
    private let serialQueue = DispatchQueue(label: "com.yourapp.datasetLoaderQueue")
    private var shalaqazaqDatasetCache: [String: [SuggestionVariation]]?
    private var qazaqWordsDatasetCache: Set<String>?
    
    func loadData() {
        Task {
            try await loadShalaqazaqDataset()
        }
        Task {
            try await loadWords()
        }
    }

    func shalaqazaqVariations() -> [String: [SuggestionVariation]] {
        serialQueue.sync {
            return shalaqazaqDatasetCache ?? [:]
        }
    }

    func qazaqWordsList() -> Set<String> {
        serialQueue.sync {
            return qazaqWordsDatasetCache ?? Set()
        }
    }

    private func loadShalaqazaqDataset() async throws {
        let loadStartDate = Date()
        print("Prepare loading shala")
        guard shalaqazaqDatasetCache == nil else {
            return
        }
        print("Started loading shala")

        let decoder = JSONDecoder()
        let fileURL = Bundle.main.url(forResource: "ShalaqazaqDatasetV2", withExtension: "json")!
        let data = try Data(contentsOf: fileURL)
        let json = try decoder.decode([String: [String: Double]].self, from: data)

        let shalaqazaqDataset = json.mapValues { rawVariations -> [SuggestionVariation] in
            rawVariations.map { (key, value) in
                SuggestionVariation(taza: key, percentage: value)
            }
        }
        print("Ended loading shala: \(Date().timeIntervalSince1970 - loadStartDate.timeIntervalSince1970)")
        
        serialQueue.sync {
            self.shalaqazaqDatasetCache = shalaqazaqDataset
        }
    }

    private func loadWords() async throws {
        let loadStartDate = Date()
        guard qazaqWordsDatasetCache == nil else {
            return
        }
        print("Started loading words")
        let fileURL = Bundle.main.url(forResource: "qazaqWordsList", withExtension: "txt")!
        let data = try Data(contentsOf: fileURL)
        let textData = String(data: data, encoding: .utf8)!
            .split(separator: "\n")
            .map(String.init)
        print("Ended loading words: \(Date().timeIntervalSince1970 - loadStartDate.timeIntervalSince1970)")
        serialQueue.sync {
            self.qazaqWordsDatasetCache = Set(textData)
        }
    }
}
