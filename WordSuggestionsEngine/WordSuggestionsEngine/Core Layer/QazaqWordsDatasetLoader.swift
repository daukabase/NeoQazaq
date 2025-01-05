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
        case rusDictionaryLoadingFailed
    }

    public static let shared = QazaqWordsDatasetLoader()

    private let serialQueue = DispatchQueue(label: "com.qazaqsha.batyrma.datasetLoaderQueue")
    private var shalaqazaqDatasetCache: [String: [SuggestionVariation]]?
    private var qazaqWordsDatasetCache: Set<String>?
    internal var rusWordsDatasetCache: Set<String>?

    private var currentBundle: Bundle {
        print("[DEBUG] type: \(type(of: self))")
        print("[DEBUG] bundle: \(Bundle(for: type(of: self)))")
        return Bundle(for: type(of: self))
    }
    
    private var datasetAlreadyLoading = false

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

    func commonRusWordsList() -> Set<String> {
        serialQueue.sync {
            return rusWordsDatasetCache ?? Set()
        }
    }

    public func loadData() {
        guard !datasetAlreadyLoading else { return }
        datasetAlreadyLoading = true

        Task {
            do {
                try await loadShalaqazaqDataset()
            } catch {
                print("[DEBUG] failed to load shalaqazaq dataset \(error)")
            }
        }
        Task {
            do {
                try await loadWords()
            } catch {
                print("[DEBUG] failed to load QAZ words \(error)")
            }
        }
        Task {
            do {
                try await loadRusWords()
            } catch {
                print("[DEBUG] failed to load RUS words \(error)")
            }
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
        print("Started loading QAZ words")

        guard let fileURL = currentBundle.url(forResource: "qazaqWordsList", withExtension: "txt") else {
            throw DatasetLoadError.qazaqDictionaryLoadingFailed
        }

        let data = try Data(contentsOf: fileURL)
        let textData = String(data: data, encoding: .utf8)!
            .split(separator: "\n")
            .map(String.init)

        print("Ended loading QAZ words: \(Date().timeIntervalSince1970 - loadStartDate.timeIntervalSince1970)")
        serialQueue.sync {
            self.qazaqWordsDatasetCache = Set(textData)
        }
    }
    
    private func loadRusWords() async throws {
        let loadStartDate = Date()
        guard rusWordsDatasetCache == nil else {
            return
        }
        print("Started loading RUS words")

        guard let fileURL = currentBundle.url(forResource: "russianWordsDataset", withExtension: "txt") else {
            throw DatasetLoadError.rusDictionaryLoadingFailed
        }

        let data = try Data(contentsOf: fileURL)
        let textData = String(data: data, encoding: .utf8)!
            .split(separator: "\r\n")
            .map(String.init)
        print("Ended loading RUS words: \(Date().timeIntervalSince1970 - loadStartDate.timeIntervalSince1970)")
        serialQueue.sync {
            self.rusWordsDatasetCache = Set(textData)
        }
    }
}
