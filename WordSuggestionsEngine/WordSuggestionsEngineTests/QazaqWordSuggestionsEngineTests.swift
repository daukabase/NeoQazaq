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
        // need some time to load data from memory
        sleep(1)
    }

    override func tearDown() {
        engine = nil
    }

    // MARK: - Base case

    func test_baseWords() {
        Constants.shalaAndTazaMap.forEach { (shala, expectedTaza) in
            suggestion(for: shala, isEqualTo: expectedTaza)
        }
    }

    func test_checkDataSetLoading() {
        XCTAssertTrue(QazaqWordsDatasetLoader.shared.commonRusWordsList().count > 500)
        XCTAssertTrue(QazaqWordsDatasetLoader.shared.qazaqWordsList().count > 10000)
        XCTAssertTrue(QazaqWordsDatasetLoader.shared.shalaqazaqVariations().keys.count > 1000)
    }

    func test_baseWords_endings() {
        suggestion(for: "казагым", isEqualTo: "қазағым")
        suggestion(for: "казагын", isEqualTo: "қазағың")
        suggestion(for: "казагы", isEqualTo: "қазағы")
    }

    // MARK: - Private

    func suggestion(for word: String, isEqualTo expected: String) {
        let suggestedWords = engine.suggestWords(for: word)

        XCTAssertEqual(suggestedWords.first?.word, expected)
    }

    func suggestion(for word: String, isEqualTo expected: [GeneratedSimilarWord]) {
        let suggestedWords = engine.suggestWords(for: word)

        XCTAssertEqual(suggestedWords, expected)
    }
}

private enum Constants {
    static let shalaAndTazaMap: [(String, String)] = [
        ("казак", "қазақ"),
        ("ертен", "ертең"),
        ("ренжигиш", "ренжігіш"),
        ("даулеттилик","дәулеттілік")
    ]
}
