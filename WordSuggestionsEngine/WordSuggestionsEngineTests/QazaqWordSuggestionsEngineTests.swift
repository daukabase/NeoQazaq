//
//  QazaqWordSuggestionsEngineTests.swift
//
//  Created by Daulet Almagambetov on 07.04.2024.
//

import XCTest
@testable import WordSuggestionsEngine

final class QazaqWordSuggestionsEngineTests: XCTestCase {

    var engine: WordSuggestionsEngine!

    override func setUp() {
        engine = QazaqWordSuggestionsEngineV2()
        QazaqWordsDatasetLoader.shared.loadData()
    }

    override func tearDown() {
        engine = nil
    }

    // MARK: - Base case

    func test_baseWords() {
        suggestion(for: "казак", isEqualTo: "казақ")
    }

    func suggestion(for word: String, isEqualTo expected: String) {
        let suggestedWords = engine.suggestWords(for: word)

        XCTAssertEqual(suggestedWords.first?.word, expected)
    }

    func suggestion(for word: String, isEqualTo expected: [GeneratedSimilarWord]) {
        let suggestedWords = engine.suggestWords(for: word)

        XCTAssertEqual(suggestedWords, expected)
    }
}
