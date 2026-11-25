//
//  PredictiveTextTests.swift
//  WordSuggestionsEngineTests
//

import XCTest
@testable import WordSuggestionsEngine

final class PredictiveTextTests: XCTestCase {
    private let predictive = PredictiveText.shared

    // MARK: - Typing context

    func test_typingContext() {
        XCTAssertEqual(TypingContext(text: "").word, "")
        XCTAssertTrue(TypingContext(text: "").isSentenceStart)

        let midWord = TypingContext(text: "Сәлем, қала")
        XCTAssertEqual(midWord.word, "қала")
        XCTAssertEqual(midWord.previousWord, "сәлем", "a comma doesn't break the context")
        XCTAssertFalse(midWord.isSentenceStart)

        let afterSpace = TypingContext(text: "Мен мектепке ")
        XCTAssertEqual(afterSpace.word, "")
        XCTAssertEqual(afterSpace.previousWord, "мектепке")

        let newSentence = TypingContext(text: "Рахмет! ")
        XCTAssertEqual(newSentence.word, "")
        XCTAssertNil(newSentence.previousWord)
        XCTAssertTrue(newSentence.isSentenceStart)
    }

    // MARK: - Letter matching

    func test_fold() {
        XCTAssertEqual(PredictiveText.fold("қазақстан"), "казакстан")
        XCTAssertEqual(PredictiveText.fold("бүгін"), "бугин")
        XCTAssertEqual(PredictiveText.fold("ёлка"), "елка")
    }

    func test_compatibility_plainLettersMayStandForKazakhOnes() {
        XCTAssertTrue(PredictiveText.isCompatible(typed: "кан", with: "қандай"))
        XCTAssertTrue(PredictiveText.isCompatible(typed: "быр", with: "бір"), "і may be typed as ы")
        XCTAssertTrue(PredictiveText.isCompatible(typed: "бир", with: "бір"), "і may be typed as и")
        XCTAssertFalse(PredictiveText.isCompatible(typed: "қан", with: "кант"), "a typed Kazakh letter must match")
        XCTAssertFalse(PredictiveText.isCompatible(typed: "канд", with: "кан"), "candidate shorter than typed")
    }

    // MARK: - Predictions from the bundled data

    private func requireData() throws {
        try XCTSkipUnless(predictive.isAvailable, "prediction data not built (scripts/build_frequencies.py)")
    }

    func test_completion_shalaInputFindsKazakhWords() throws {
        try requireData()
        let words = predictive.completions(for: "кан", limit: 6).map(\.word)
        XCTAssertTrue(words.contains("қандай"), "\(words)")
    }

    func test_completion_typedKazakhLettersAreRespected() throws {
        try requireData()
        let words = predictive.completions(for: "қаз", limit: 6).map(\.word)
        XCTAssertFalse(words.isEmpty)
        XCTAssertTrue(words.allSatisfy { $0.hasPrefix("қаз") }, "\(words)")
    }

    func test_exactWordScores_areFound() throws {
        try requireData()
        XCTAssertNotNil(predictive.score(of: "пожалуйста"))
        XCTAssertNotNil(predictive.score(of: "қазақ"))
        XCTAssertNil(predictive.score(of: "абвгдежзик"))
    }

    func test_chatWords_rankFirst() throws {
        try requireData()
        XCTAssertEqual(predictive.completions(for: "пож", limit: 1).first?.word, "пожалуйста")
        XCTAssertEqual(predictive.completions(for: "рах", limit: 1).first?.word, "рахмет")
        XCTAssertEqual(predictive.completions(for: "жак", limit: 1).first?.word, "жақсы")
    }

    func test_completion_russian() throws {
        try requireData()
        XCTAssertTrue(predictive.completions(for: "приве", limit: 6).map(\.word).contains("привет"))
        let russianOnly = predictive.completions(for: "объ", limit: 6)
        XCTAssertTrue(russianOnly.allSatisfy { $0.language == .russian })
    }

    func test_completion_neverReturnsWhatWasTyped() throws {
        try requireData()
        XCTAssertFalse(predictive.completions(for: "қала", limit: 6).map(\.word).contains("қала"))
    }

    func test_nextWords() throws {
        try requireData()
        XCTAssertFalse(predictive.nextWords(after: "және").isEmpty)
        XCTAssertFalse(predictive.nextWords(after: nil, language: .kazakh).isEmpty, "Kazakh sentence starters")
        XCTAssertFalse(predictive.nextWords(after: nil, language: .russian).isEmpty, "Russian sentence starters")
        XCTAssertEqual(PredictiveText.language(of: "Рахмет, бүгін келемін."), .kazakh)
        XCTAssertEqual(PredictiveText.language(of: "Спасибо, увидимся."), .russian)
        XCTAssertTrue(predictive.nextWords(after: "абвгдежзик").isEmpty)
    }

    func test_neverPredictsVulgarWords() throws {
        try requireData()
        for prefix in ["сіг", "сиг", "жәл", "бок"] {
            let words = predictive.completions(for: prefix, limit: 10).map(\.word)
            XCTAssertFalse(words.contains { ["сігіп", "сігіліп", "жәлеп", "боқмұрын"].contains($0) }, "\(words)")
        }
    }

    func test_speed() throws {
        try requireData()
        let prefixes = ["к", "ка", "кан", "канд", "қаза", "мект", "привет", "сегод", "бугин", "жаксы"]
        let start = Date()
        for _ in 0..<50 { for prefix in prefixes { _ = predictive.completions(for: prefix) } }
        let perCall = Date().timeIntervalSince(start) / Double(50 * prefixes.count)
        XCTAssertLessThan(perCall, 0.005, "completion should take well under 5 ms (took \(perCall * 1000) ms)")
    }
}
