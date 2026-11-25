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
        let loader = QazaqWordsDatasetLoader.shared
        XCTAssertTrue(loader.isLoaded)
        XCTAssertTrue(loader.russianWordCount > 500)
        XCTAssertTrue(loader.kazakhWordCount > 10000)
        XCTAssertTrue(loader.shalaKeyCount > 1000)
        XCTAssertFalse(loader.autocorrectAllowList.isEmpty)
    }

    func test_lookups() {
        let loader = QazaqWordsDatasetLoader.shared
        XCTAssertEqual(loader.variations(for: "салем"), [SuggestionVariation(taza: "сәлем", percentage: 1)])
        XCTAssertNil(loader.variations(for: "абвгдеёжз"))
        XCTAssertTrue(loader.containsKazakhWord("мектеп"))
        XCTAssertTrue(loader.containsKazakhWord("Мектеп"), "lookups ignore case")
        XCTAssertFalse(loader.containsKazakhWord("салем"))
        XCTAssertTrue(loader.containsRussianWord("спасибо"))
    }

    func test_matchKinds() {
        XCTAssertEqual(engine.suggestWords(for: "салем").first?.kind, .exactKey)
        XCTAssertEqual(engine.suggestWords(for: "казагым").first?.kind, .rootWithGeneratedEnding)
        XCTAssertTrue(engine.suggestWords(for: "канд").allSatisfy { $0.kind == .rootWithRawSuffix },
                      "partial words glued to a raw ending are fragments")
        XCTAssertEqual(engine.suggestWords(for: "барамын").first?.kind, .endingOnlyChange,
                       "the root is already correct; only the ending would change")
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
