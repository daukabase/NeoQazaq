//
//  QazaqWordsDatasetLoader.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 17.02.2024.
//

import Foundation

struct SuggestionVariation: Codable, Equatable {
    let taza: String
    let percentage: Double
}

/// Read-only access to the bundled dictionaries.
///
/// The files are memory-mapped and binary-searched (see `SortedLinesFile`), so opening them
/// is instant and costs almost no heap memory. The old loader decoded a 2 MB JSON into Swift
/// dictionaries, which peaked at ~37 MB and could get the keyboard killed by iOS.
///
/// Regenerate the files with `scripts/build_dictionaries.py`.
public final class QazaqWordsDatasetLoader {
    public static let shared = QazaqWordsDatasetLoader()

    /// Typed-with-Russian-letters key → proper Kazakh words with scores.
    private let shala: SortedLinesFile?
    /// Lower-cased Kazakh word forms.
    private let kazakhWords: SortedLinesFile?
    /// Lower-cased Russian words (small fallback list; the keyboard also asks the system spell checker).
    private let russianWords: SortedLinesFile?
    /// Typed forms that must auto-correct even though they look like dictionary words.
    public let autocorrectAllowList: Set<String>

    private init() {
        let bundle = Bundle(for: QazaqWordsDatasetLoader.self)
        func open(_ name: String, _ ext: String) -> SortedLinesFile? {
            guard let url = bundle.url(forResource: name, withExtension: ext) else {
                assertionFailure("Missing dictionary \(name).\(ext); run scripts/build_dictionaries.py")
                return nil
            }
            return try? SortedLinesFile(url: url)
        }
        shala = open("shala", "tsv")
        kazakhWords = open("kk_words", "txt")
        russianWords = open("ru_words", "txt")

        if let url = bundle.url(forResource: "autocorrect_allowlist", withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            autocorrectAllowList = Set(text.split(separator: "\n").map(String.init))
        } else {
            autocorrectAllowList = []
        }
    }

    /// Kept for call sites that warmed up the old asynchronous loader. Opening is now synchronous.
    public func loadData() {}

    var isLoaded: Bool { shala != nil && kazakhWords != nil && russianWords != nil }

    var shalaKeyCount: Int { shala?.count ?? 0 }
    var kazakhWordCount: Int { kazakhWords?.count ?? 0 }
    var russianWordCount: Int { russianWords?.count ?? 0 }

    /// Proper-Kazakh variations for a typed key, most likely first.
    func variations(for key: String) -> [SuggestionVariation]? {
        guard let line = shala?.value(for: key), !line.isEmpty else { return nil }
        let variations = line.split(separator: "|").compactMap { part -> SuggestionVariation? in
            guard let colon = part.lastIndex(of: ":"), let score = Double(part[part.index(after: colon)...]) else {
                return nil
            }
            return SuggestionVariation(taza: String(part[..<colon]), percentage: score)
        }
        return variations.isEmpty ? nil : variations
    }

    public func containsKazakhWord(_ word: String) -> Bool {
        kazakhWords?.contains(word.lowercased()) ?? false
    }

    public func containsRussianWord(_ word: String) -> Bool {
        russianWords?.contains(word.lowercased()) ?? false
    }
}
