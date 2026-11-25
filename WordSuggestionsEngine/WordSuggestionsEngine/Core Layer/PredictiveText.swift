//
//  PredictiveText.swift
//  WordSuggestionsEngine
//
//  Word completion and next-word prediction for Kazakh and Russian in one keyboard.
//
//  A statistical language model: the data files hold how often words and word pairs occur
//  in Kazakh and Russian Wikipedia (built by scripts/build_frequencies.py). Lookups are
//  binary searches over memory-mapped files, so it costs almost no memory and works offline,
//  without Full Access. See specs/02-bilingual-prediction-design.md.
//

import Foundation

public final class PredictiveText {
    public static let shared = PredictiveText()

    public enum Language: Equatable, Sendable {
        case kazakh, russian
    }

    public struct Prediction: Equatable {
        public let word: String
        /// 1...255, log frequency within its language.
        public let score: Int
        public let language: Language
    }

    private let completeKazakh: SortedLinesFile?
    private let completeRussian: SortedLinesFile?
    private let prefixTop: SortedLinesFile?
    private let nextWordsFile: SortedLinesFile?

    /// Most lines scanned for one prefix. Prefixes of 1–3 letters use precomputed lists instead.
    private let scanLimit = 3_000

    init(bundle: Bundle = Bundle(for: PredictiveText.self)) {
        func open(_ name: String) -> SortedLinesFile? {
            bundle.url(forResource: name, withExtension: "tsv").flatMap { try? SortedLinesFile(url: $0) }
        }
        completeKazakh = open("complete_kk")
        completeRussian = open("complete_ru")
        prefixTop = open("prefix_top")
        nextWordsFile = open("next_words")
    }

    /// False if the data files weren't built/bundled; the keyboard then shows no predictions.
    public var isAvailable: Bool { completeKazakh != nil && completeRussian != nil }

    // MARK: - Completion

    /// Words that start with what the user typed, most frequent first. Kazakh typed without its
    /// letters still matches ("кан" → қандай), but letters the user did type must match exactly.
    public func completions(for typed: String, limit: Int = 3) -> [Prediction] {
        let typed = typed.lowercased()
        guard !typed.isEmpty, isAvailable else { return [] }

        var languages: [Language] = [.kazakh, .russian]
        if typed.contains(where: Self.kazakhOnlyLetters.contains) { languages = [.kazakh] }
        if typed.contains(where: Self.russianOnlyLetters.contains) { languages = [.russian] }

        var results: [Prediction] = []
        for language in languages {
            results += candidates(for: typed, language: language)
        }
        results.sort { $0.score > $1.score }
        var seen = Set<String>()
        var unique: [Prediction] = []
        for prediction in results where prediction.word != typed && !seen.contains(prediction.word) {
            seen.insert(prediction.word)
            unique.append(prediction)
            if unique.count == limit { break }
        }
        return unique
    }

    /// Frequency score of an exact word in either language, if known.
    public func score(of word: String) -> Int? {
        let word = word.lowercased()
        let scores = [completeKazakh, completeRussian].compactMap { $0 }.compactMap { frequency(of: word, in: $0) }
        return scores.max()
    }

    // MARK: - Next word

    /// Likely next words after `previousWord`. Pass nil at the start of a sentence; `language`
    /// then picks Kazakh or Russian sentence starters.
    public func nextWords(after previousWord: String?, language: Language = .kazakh, limit: Int = 3) -> [String] {
        let key = previousWord?.lowercased() ?? (language == .kazakh ? "<s>:kk" : "<s>:ru")
        guard !key.isEmpty, let line = nextWordsFile?.value(for: key), !line.isEmpty else { return [] }
        return Array(line.split(separator: "|").map(String.init).prefix(limit))
    }

    /// The language of text already typed: Kazakh if it has any Kazakh-only letter, else Russian
    /// if it has Cyrillic letters, else Kazakh.
    public static func language(of text: String) -> Language {
        if text.lowercased().contains(where: kazakhOnlyLetters.contains) { return .kazakh }
        return text.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) } ? .russian : .kazakh
    }

    // MARK: - Private

    private func candidates(for typed: String, language: Language) -> [Prediction] {
        guard let file = language == .kazakh ? completeKazakh : completeRussian else { return [] }
        let tag = language == .kazakh ? "kk" : "ru"
        let folded = Self.fold(typed)

        // Short prefixes: precomputed top lists (exact list when the user typed Kazakh letters or ё).
        if folded.count <= 3, let prefixTop {
            let hasExactLetters = typed.contains { Self.kazakhOnlyLetters.contains($0) || $0 == "ё" }
            let key = hasExactLetters ? "\(tag)=\(typed)" : "\(tag):\(folded)"
            if let line = prefixTop.value(for: key) {
                let words = line.split(separator: "|").map(String.init)
                    .filter { Self.isCompatible(typed: typed, with: $0) }
                if !words.isEmpty {
                    // The list is ordered by frequency; give later entries slightly lower scores.
                    return words.enumerated().map { index, word in
                        Prediction(word: word, score: frequency(of: word, in: file) ?? max(1, 200 - index), language: language)
                    }
                }
            }
        }

        var best: [String: Prediction] = [:]
        for line in file.lines(withPrefix: folded, limit: scanLimit) {
            guard let entry = Self.parseCompletionLine(line), Self.isCompatible(typed: typed, with: entry.word) else { continue }
            if (best[entry.word]?.score ?? 0) < entry.score {
                best[entry.word] = Prediction(word: entry.word, score: entry.score, language: language)
            }
        }
        return Array(best.values)
    }

    private func frequency(of word: String, in file: SortedLinesFile) -> Int? {
        // Lines whose key is exactly the folded word sort first in its prefix range.
        let folded = Self.fold(word)
        for line in file.lines(withPrefix: folded, limit: 50) {
            guard line.hasPrefix(folded + "\t") else { break }
            if let entry = Self.parseCompletionLine(line), entry.word == word { return entry.score }
        }
        return nil
    }

    /// "folded\tword\tscore" → (word, score)
    static func parseCompletionLine(_ line: String) -> (word: String, score: Int)? {
        let parts = line.split(separator: "\t")
        guard parts.count == 3, let score = Int(parts[2]) else { return nil }
        return (String(parts[1]), score)
    }

    static let kazakhOnlyLetters: Set<Character> = Set("әғқңөұүһі")
    /// Letters common in Russian but (almost) absent from native Kazakh words.
    static let russianOnlyLetters: Set<Character> = Set("ёъщэ")

    /// What people type instead of each Kazakh letter.
    static let plainLetters: [Character: Set<Character>] = [
        "ә": ["а"], "ғ": ["г"], "қ": ["к"], "ң": ["н"], "ө": ["о"],
        "ұ": ["у"], "ү": ["у"], "һ": ["х"], "і": ["и", "ы"], "ё": ["е"],
    ]

    /// Lower-cased word with Kazakh letters (and ё) replaced by what people type instead.
    /// і becomes и; the data files index both и and ы variants of words with і.
    static func fold(_ word: String) -> String {
        String(word.map { plainLetters[$0].map { $0.contains("и") ? "и" : $0.first! } ?? $0 })
    }

    /// Whether `candidate` can be what the user meant by `typed` (a prefix of it):
    /// letters typed as-is must match; plain letters may stand for their Kazakh versions.
    static func isCompatible(typed: String, with candidate: String) -> Bool {
        let typedLetters = Array(typed)
        let candidateLetters = Array(candidate)
        guard candidateLetters.count >= typedLetters.count else { return false }
        for (t, c) in zip(typedLetters, candidateLetters) where t != c {
            guard let plain = plainLetters[c], plain.contains(t) else { return false }
        }
        return true
    }
}

/// Where the cursor is in the sentence, from the text before it.
public struct TypingContext: Equatable {
    /// The word being typed (trailing letters, hyphens, apostrophes); empty right after a space.
    public let word: String
    /// The last complete word before it, lower-cased; nil at the start of a sentence.
    public let previousWord: String?
    public let isSentenceStart: Bool

    public init(text: String) {
        let isWordCharacter: (Character) -> Bool = { $0.isLetter || $0 == "-" || $0 == "'" || $0 == "’" }
        word = String(text.reversed().prefix(while: isWordCharacter).reversed())
        let before = text.dropLast(word.count).trimmingCharacters(in: .whitespaces)
        isSentenceStart = before.isEmpty || before.last.map { ".!?\n".contains($0) } == true
        // A comma, colon or semicolon doesn't break the context: "Сәлем, |" still predicts from "сәлем".
        let beforePunctuation = before.trimmingCharacters(in: CharacterSet(charactersIn: ",;: "))
        if isSentenceStart || beforePunctuation.last.map(isWordCharacter) != true {
            previousWord = nil
        } else {
            previousWord = String(beforePunctuation.reversed().prefix(while: isWordCharacter).reversed()).lowercased()
        }
    }
}
