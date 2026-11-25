//
//  TypingStats.swift
//  QazaqFoundation
//
//  "Batyrma restored 1,240 letters for you this month." The keyboard counts its corrections
//  and writes the totals to the app group; the app shows them on the home screen. Only
//  numbers are stored, never text. The keyboard can write to the app group only with Full
//  Access, so users without it simply see no stats.
//

import Foundation

public enum TypingStats {
    public struct Snapshot: Equatable {
        public var monthLetters = 0
        public var monthWords = 0
        public var totalLetters = 0
        public var totalWords = 0

        public var isEmpty: Bool { totalWords == 0 }
    }

    private static let monthKey = "statsMonth"
    private static let monthLettersKey = "statsMonthLetters"
    private static let monthWordsKey = "statsMonthWords"
    private static let totalLettersKey = "statsTotalLetters"
    private static let totalWordsKey = "statsTotalWords"

    private static let kazakhLetters = Set("әғқңөұүһіӘҒҚҢӨҰҮҺІ")

    /// Keyboard side: one autocorrection was applied ("калайсын" → "қалайсың").
    public static func recordCorrection(
        original: String,
        replacement: String,
        defaults: UserDefaults = .localAppGroup,
        now: Date = Date()
    ) {
        let restored = max(0, kazakhLetterCount(replacement) - kazakhLetterCount(original))
        let month = monthString(now)
        if defaults.string(forKey: monthKey) != month {
            defaults.set(month, forKey: monthKey)
            defaults.set(0, forKey: monthLettersKey)
            defaults.set(0, forKey: monthWordsKey)
        }
        increment(monthLettersKey, by: restored, in: defaults)
        increment(monthWordsKey, by: 1, in: defaults)
        increment(totalLettersKey, by: restored, in: defaults)
        increment(totalWordsKey, by: 1, in: defaults)
    }

    /// App side.
    public static func snapshot(defaults: UserDefaults = .localAppGroup, now: Date = Date()) -> Snapshot {
        var snapshot = Snapshot(
            totalLetters: defaults.integer(forKey: totalLettersKey),
            totalWords: defaults.integer(forKey: totalWordsKey)
        )
        if defaults.string(forKey: monthKey) == monthString(now) {
            snapshot.monthLetters = defaults.integer(forKey: monthLettersKey)
            snapshot.monthWords = defaults.integer(forKey: monthWordsKey)
        }
        return snapshot
    }

    static func kazakhLetterCount(_ text: String) -> Int {
        text.filter(kazakhLetters.contains).count
    }

    private static func increment(_ key: String, by value: Int, in defaults: UserDefaults) {
        guard value > 0 else { return }
        defaults.set(defaults.integer(forKey: key) + value, forKey: key)
    }

    private static func monthString(_ date: Date) -> String {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}
