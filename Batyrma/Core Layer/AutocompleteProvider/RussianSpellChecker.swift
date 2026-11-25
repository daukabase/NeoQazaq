//
//  RussianSpellChecker.swift
//  Batyrma
//
//  Asks the system spell checker (offline, built into iOS) whether a word is valid Russian,
//  so Russian words are never auto-replaced with Kazakh look-alikes (кит → қит, дал → дәл).
//  specs/01-fix-spec.md C4(a).
//

import UIKit

final class RussianSpellChecker {
    private let checker = UITextChecker()
    private let language: String?
    private let lock = NSLock()
    private var cache: [String: Bool] = [:]
    private let cacheLimit = 2_000

    /// Letters that only Kazakh uses: a word containing one can't be Russian.
    private static let kazakhOnlyLetters = Set("әғқңөұүһі")

    init() {
        let languages = UITextChecker.availableLanguages
        language = languages.first { $0 == "ru_RU" } ?? languages.first { $0.hasPrefix("ru") }
    }

    var isAvailable: Bool { language != nil }

    func isValidWord(_ word: String) -> Bool {
        let word = word.lowercased()
        guard let language, word.count > 1, !word.contains(where: Self.kazakhOnlyLetters.contains) else {
            return false
        }
        if let cached = lock.withLock({ cache[word] }) { return cached }

        let check = { [checker] () -> Bool in
            let range = NSRange(location: 0, length: word.utf16.count)
            return checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: language)
                .location == NSNotFound
        }
        // UITextChecker is a UIKit class; autocomplete runs on a background task, so hop to main.
        let isValid = Thread.isMainThread ? check() : DispatchQueue.main.sync(execute: check)

        lock.withLock {
            if cache.count >= cacheLimit { cache.removeAll(keepingCapacity: true) }
            cache[word] = isValid
        }
        return isValid
    }
}
