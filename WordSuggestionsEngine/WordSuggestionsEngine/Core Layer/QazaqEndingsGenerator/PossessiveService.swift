//
//  PossessiveService.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 14.02.2024.
//


class PossessiveService: Service {
    enum Constants {
        static let consonantAlteration = [
            "қ": "ғ",
            "п": "б",
            "к": "г"
        ]
        static let consonantAlterationReversed = [
            "ғ": "қ",
            "б": "п",
            "г": "к"
        ]
    }
    private var possessive: Form
    private var quantitative: Quantity
    private let hardVowels = "аоуұы"
    private let softVowels = "әеиөүі"
    private var vowels: String {
        return hardVowels + softVowels
    }
    private let consonantAlteration = Constants.consonantAlteration
    
    private let darDerConsonants = "лмнңжз"
    private let tarTerConsonants = "пфкқтсшщхцчһбвгд"

    private let endings = [
        ["ым", "ім", "м", "м"],
        ["ың", "ің", "ң", "ң"],
        ["ыңыз", "іңіз", "ңыз", "ңіз"],
        ["ы", "і", "сы", "сі"],
        ["ымыз", "іміз", "мыз", "міз"]
    ]

    init(possessive: Form, quantitative: Quantity) {
        self.possessive = possessive
        self.quantitative = quantitative
    }

    func process(text: String) -> String {
        let line = getPersonType(possessive: possessive, quantitative: quantitative)
        let column = getLastVowelType(text: text)

        let text = exchangeLastConsonantIfNeeded(text: text)
        return text + endings[line][column]
    }

    // write function that exchanges last consonant letter if it is consonantAlteration
    private func exchangeLastConsonantIfNeeded(text: String) -> String {
        guard let lastLetter = text.last.map(String.init), let alterationLetter = consonantAlteration[lastLetter] else { return text }
        return String(text.dropLast()) + alterationLetter
    }

    private func getPersonType(possessive: Form, quantitative: Quantity) -> Int {
        switch possessive {
        case .first:
            return quantitative == .singular ? 0 : 4
        case .second:
            return 1
        case .secondRespectful:
            return 2
        default:
            return 3
        }
    }

    private func getLastVowelType(text: String) -> Int {
        var result = 0

        if let lastLetter = text.last, vowels.contains(lastLetter) {
            result += 2
        }

        if checkIfLastVowelSoft(text: text) {
            result += 1
        }

        return result
    }

    private func checkIfLastVowelSoft(text: String) -> Bool {
        for char in text.reversed() {
            if hardVowels.contains(char) {
                return false
            }
            if softVowels.contains(char) {
                return true
            }
        }
        return false
    }
    
    private func getLastVowel(text: String) -> String {
        for char in text.reversed() {
            if vowels.contains(char) {
                return String(char)
            }
        }
        return ""
    }
}
