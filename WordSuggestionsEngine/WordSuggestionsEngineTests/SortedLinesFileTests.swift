//
//  SortedLinesFileTests.swift
//  WordSuggestionsEngineTests
//

import XCTest
@testable import WordSuggestionsEngine

final class SortedLinesFileTests: XCTestCase {
    private func makeFile(_ lines: [String]) throws -> SortedLinesFile {
        let sorted = lines.sorted { Array($0.utf8).lexicographicallyPrecedes(Array($1.utf8)) }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".tsv")
        try (sorted.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return try SortedLinesFile(url: url)
    }

    func test_valueLookup_firstMiddleLastAndMissing() throws {
        let file = try makeFile(["ақ\twhite", "бар\tthere is", "сәлем\thello", "өзен\triver", "ұлы\tgreat"])
        XCTAssertEqual(file.count, 5)
        XCTAssertEqual(file.value(for: "ақ"), "white")
        XCTAssertEqual(file.value(for: "сәлем"), "hello")
        XCTAssertEqual(file.value(for: "ұлы"), "great")
        XCTAssertNil(file.value(for: "жоқ"))
        XCTAssertNil(file.value(for: ""))
    }

    func test_prefixOfAKey_isNotAMatch() throws {
        let file = try makeFile(["қазақ", "қазақстан"])
        XCTAssertTrue(file.contains("қазақ"))
        XCTAssertTrue(file.contains("қазақстан"))
        XCTAssertFalse(file.contains("қаза"))
        XCTAssertFalse(file.contains("қазақс"))
        XCTAssertEqual(file.value(for: "қазақ"), "", "a line without a tab has an empty value")
    }

    func test_bundledDictionaries_areSortedAndClean() throws {
        let bundle = Bundle(for: QazaqWordsDatasetLoader.self)
        for (name, ext) in [("shala", "tsv"), ("kk_words", "txt"), ("ru_words", "txt")] {
            let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: ext), name)
            let text = try String(contentsOf: url, encoding: .utf8)
            let keys = text.split(separator: "\n").map { $0.split(separator: "\t").first.map(String.init) ?? "" }
            let isSorted = zip(keys, keys.dropFirst()).allSatisfy { Array($0.utf8).lexicographicallyPrecedes(Array($1.utf8)) }
            XCTAssertTrue(isSorted, "\(name).\(ext) must be sorted by UTF-8 bytes (run scripts/build_dictionaries.py)")
            XCTAssertNil(text.range(of: "[A-Za-z]", options: .regularExpression),
                         "\(name).\(ext) must not contain Latin look-alike letters")
        }
    }
}
