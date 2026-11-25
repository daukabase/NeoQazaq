//
//  PersonalStoreTests.swift
//  WordSuggestionsEngineTests
//

import XCTest
@testable import WordSuggestionsEngine

final class PersonalStoreTests: XCTestCase {
    private let suiteName = "PersonalStoreTests"
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func test_learnIgnoreReject_persistAcrossInstances() {
        let store = PersonalStore(defaults: defaults)
        store.learn("Ертен")
        store.ignore("мең")
        store.reject(typed: "ол", candidate: "өл")

        let reloaded = PersonalStore(defaults: defaults)
        XCTAssertTrue(reloaded.isLearned("ертен"), "case-insensitive")
        XCTAssertTrue(reloaded.isIgnored("мең"))
        XCTAssertTrue(reloaded.isRejected(typed: "Ол", candidate: "өл"))
        XCTAssertFalse(reloaded.isRejected(typed: "ол", candidate: "мең"))
    }

    func test_unlearnAndRemoveIgnored() {
        let store = PersonalStore(defaults: defaults)
        store.learn("ертен")
        store.ignore("мең")
        store.unlearn("ертен")
        store.removeIgnored("мең")
        XCTAssertFalse(store.isLearned("ертен"))
        XCTAssertFalse(store.isIgnored("мең"))
    }

    func test_learnedWords_evictLeastRecentlyUsed() {
        let store = PersonalStore(defaults: defaults, maxLearned: 3, maxRejected: 3)
        ["а1", "а2", "а3"].forEach(store.learn)
        store.learn("а1")          // refresh а1
        store.learn("а4")          // evicts а2, the least recently used
        XCTAssertTrue(store.isLearned("а1"))
        XCTAssertFalse(store.isLearned("а2"))
        XCTAssertTrue(store.isLearned("а3"))
        XCTAssertTrue(store.isLearned("а4"))
        XCTAssertEqual(store.learnedWords.count, 3)
    }

    func test_resetToken_wipesOncePerToken() {
        let store = PersonalStore(defaults: defaults)
        store.learn("ертен")
        store.resetIfRequested(token: nil)
        XCTAssertTrue(store.isLearned("ертен"), "no token, no reset")

        store.resetIfRequested(token: "A")
        XCTAssertFalse(store.isLearned("ертен"))

        store.learn("ертен")
        store.resetIfRequested(token: "A")
        XCTAssertTrue(store.isLearned("ертен"), "the same token is applied only once")
    }
}
