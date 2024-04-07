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

public final class QazaqWordsDatasetLoader {
    enum DatasetLoadError: Error {
        case shalaqazaqLoadingFailed
        case qazaqDictionaryLoadingFailed
    }

    public static let shared = QazaqWordsDatasetLoader()

    private let serialQueue = DispatchQueue(label: "com.qazaqsha.batyrma.datasetLoaderQueue")
    private var shalaqazaqDatasetCache: [String: [SuggestionVariation]]?
    private var qazaqWordsDatasetCache: Set<String>?

    private var currentBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    private init() {
        loadData()
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

    public func loadData() {
        Task {
            try await loadShalaqazaqDataset()
        }
        Task {
            try await loadWords()
        }
    }

    private func loadShalaqazaqDataset() async throws {
        let loadStartDate = Date()
        guard shalaqazaqDatasetCache == nil else {
            return
        }
        print("Started loading shala")

        guard let fileURL = currentBundle.url(forResource: "ShalaqazaqDatasetV2", withExtension: "json") else {
            throw DatasetLoadError.shalaqazaqLoadingFailed
        }
        let data = try Data(contentsOf: fileURL)
        let json = try JSONDecoder().decode([String: [String: Double]].self, from: data)

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

        guard let fileURL = currentBundle.url(forResource: "qazaqWordsList", withExtension: "txt") else {
            throw DatasetLoadError.qazaqDictionaryLoadingFailed
        }

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
