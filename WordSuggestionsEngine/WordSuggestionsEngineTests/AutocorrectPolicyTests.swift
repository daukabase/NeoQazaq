//
//  AutocorrectPolicyTests.swift
//  WordSuggestionsEngineTests
//
//  Acceptance criteria for specs/01-fix-spec.md C1 (stop replacing correct words) and C3 (fragments).
//

import XCTest
@testable import WordSuggestionsEngine

final class AutocorrectPolicyTests: XCTestCase {
    private var engine: QazaqWordSuggestionsEngineV2!
    private var defaults: UserDefaults!
    private var store: PersonalStore!
    private var policy: AutocorrectPolicy!
    private let suiteName = "AutocorrectPolicyTests"

    override func setUp() {
        engine = QazaqWordSuggestionsEngineV2()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = PersonalStore(defaults: defaults)
        // Stand-in for UITextChecker (the keyboard injects the real one).
        let russian: Set<String> = ["кит", "канал", "колхоз", "сценарий", "дал", "дам", "казак"]
        policy = .standard(personal: store, extraRussianCheck: { russian.contains($0.lowercased()) })
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    /// What pressing space would do: the replacement word, or nil if the word stays as typed.
    private func autocorrection(for typed: String, sentenceStart: Bool = false) -> String? {
        engine.suggestWords(for: typed.lowercased())
            .sorted { $0.similarity > $1.similarity }
            .first { policy.decide(typed: typed, candidate: $0, isSentenceStart: sentenceStart) == .autocorrect }?
            .word
    }

    private func visibleSuggestions(for typed: String) -> [String] {
        engine.suggestWords(for: typed)
            .filter { policy.decide(typed: typed, candidate: $0, isSentenceStart: false) != .hide }
            .map(\.word)
    }

    // MARK: - Never replace correct words

    func test_commonKazakhWords_areNeverReplaced() {
        for word in ["ол", "бар", "сол", "сен", "болу", "онда", "ма", "ай", "нан", "сал",
                     "туралы", "орын", "ойын", "таныс", "тау", "топ", "аз", "барамын", "менде"] {
            XCTAssertNil(autocorrection(for: word), "\(word) must stay as typed")
        }
    }

    func test_russianLookalikes_areNeverReplaced() {
        for word in ["кит", "канал", "колхоз", "сценарий", "дал", "дам"] {
            XCTAssertNil(autocorrection(for: word), "\(word) is Russian and must stay as typed")
        }
    }

    /// Every "keep" row of the review file must stay as typed.
    func test_reviewFile_keepRows_areNeverReplaced() throws {
        let rows = try reviewRows()
        let keep = rows.filter { $0.action == "keep" }
        XCTAssertGreaterThan(keep.count, 200)
        for row in keep {
            XCTAssertNil(autocorrection(for: row.typed), "\(row.typed) is marked keep")
        }
    }

    // MARK: - Still restore Kazakh letters

    func test_shalaExamples_stillAutocorrect() {
        let expected = [
            "салем": "сәлем", "кандай": "қандай", "калайсын": "қалайсың", "жаксы": "жақсы",
            "бугин": "бүгін", "ертен": "ертең", "казак": "қазақ", "казакстан": "қазақстан",
        ]
        for (typed, proper) in expected {
            XCTAssertEqual(autocorrection(for: typed), proper, "\(typed) → \(proper)")
        }
    }

    func test_allowList_autocorrects() {
        for typed in QazaqWordsDatasetLoader.shared.autocorrectAllowList {
            XCTAssertNotNil(autocorrection(for: typed), "\(typed) is on the reviewed allow-list")
        }
    }

    // MARK: - Fragments, names, threshold

    func test_fragments_areHidden() {
        let suggestions = visibleSuggestions(for: "канд")
        XCTAssertFalse(suggestions.contains("қанд"))
        XCTAssertFalse(suggestions.contains("кәнд"))
    }

    func test_capitalizedWordMidSentence_isOnlySuggested() {
        XCTAssertNil(autocorrection(for: "Салем", sentenceStart: false), "probably a name")
        XCTAssertEqual(autocorrection(for: "Салем", sentenceStart: true), "сәлем")
    }

    func test_scoreOfExactly095_isSuggestOnly() {
        let neverWords = AutocorrectPolicy(isKazakhWord: { _ in false }, isRussianWord: { _ in false },
                                           allowList: [], personal: nil)
        let at095 = GeneratedSimilarWord(word: "сігіп", similarity: 0.95, kind: .exactKey)
        let above = GeneratedSimilarWord(word: "сәлем", similarity: 1, kind: .exactKey)
        XCTAssertEqual(neverWords.decide(typed: "сигип", candidate: at095, isSentenceStart: false), .suggest)
        XCTAssertEqual(neverWords.decide(typed: "салем", candidate: above, isSentenceStart: false), .autocorrect)
    }

    // MARK: - Personal store interplay (C2)

    func test_learnedWord_isNeverReplaced() {
        XCTAssertEqual(autocorrection(for: "ертен"), "ертең")
        store.learn("ертен")
        XCTAssertNil(autocorrection(for: "ертен"))
    }

    func test_rejectedCorrection_isNotReappliedButStillSuggested() {
        store.reject(typed: "бугин", candidate: "бүгін")
        XCTAssertNil(autocorrection(for: "бугин"))
        XCTAssertTrue(visibleSuggestions(for: "бугин").contains("бүгін"))
    }

    func test_ignoredWord_isHidden() {
        store.ignore("сәлем")
        XCTAssertFalse(visibleSuggestions(for: "салем").contains("сәлем"))
    }

    // MARK: - Helpers

    private struct ReviewRow { let typed: String; let action: String }

    private func reviewRows() throws -> [ReviewRow] {
        // specs/data/autocorrect-conflicts.tsv, relative to this file.
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("specs/data/autocorrect-conflicts.tsv")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw XCTSkip("review file not reachable from the test runner: \(url.path)")
        }
        return text.split(separator: "\n").dropFirst().map { line in
            let columns = line.split(separator: "\t", omittingEmptySubsequences: false)
            return ReviewRow(typed: String(columns[0]), action: String(columns[2]))
        }
    }
}
