import Foundation

extension String {
    var length: Int {
        return count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

enum Form: CaseIterable {
    case first, second, secondRespectful, third
}

enum Quantity: CaseIterable {
    case singular, plural
}

protocol Service {
    func process(text: String) -> String
}

class PossessiveService: Service {
    private var possessive: Form
    private var quantitative: Quantity
    private let hardVowels = "аоуұы"
    private let softVowels = "әеиөүі"
    private var vowels: String {
        return hardVowels + softVowels
    }
    private let consonantAlteration = [
        "қ": "ғ",
        "п": "б",
        "к": "г"
    ]
    
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

class QuantitativeService: Service {
    private let hardVowels = "аоуұы"
    private let softVowels = "әеиөүі"
    private let darDerConsonants = "лмнңжз"
    private let tarTerConsonants = "пфкқтсшщхцчһбвгд"
    private let endings = [["дар", "дер"], ["тар", "тер"], ["лар", "лер"]]
    
    var quantitative: Quantity
    
    init(quantitative: Quantity) {
        self.quantitative = quantitative
    }
    
    func process(text: String) -> String {
        if quantitative == .plural {
            return pluralize(text: text)
        } else {
            return singularize(text: text)
        }
    }
    
    private func singularize(text: String) -> String {
        if endsWithCorrectEnding(text: text) && text.count > 3 {
            let probableSingular = String(text.dropLast(3))
            if pluralize(text: probableSingular) == text {
                return probableSingular
            }
        }
        return text
    }
    
    private func pluralize(text: String) -> String {
        guard let lastLetter = text.last else { return text }
        let endingType = getEndingTypeByLastLetter(lastLetter: lastLetter)
        let vowelType = getLastVowelType(text: text)
        return text + endings[endingType][vowelType]
    }
    
    private func endsWithCorrectEnding(text: String) -> Bool {
        for i in 0..<3 {
            for j in 0..<2 {
                if text.hasSuffix(endings[i][j]) {
                    return true
                }
            }
        }
        return false
    }
    
    private func getEndingTypeByLastLetter(lastLetter: Character) -> Int {
        if darDerConsonants.contains(lastLetter) {
            return 0
        }
        if tarTerConsonants.contains(lastLetter) {
            return 1
        }
        return 2
    }
    
    private func getLastVowelType(text: String) -> Int {
        for char in text.reversed() {
            if hardVowels.contains(char) {
                return 0
            }
            if softVowels.contains(char) {
                return 1
            }
        }
        return 0
    }
}

struct QazaqEndingsGenerator {
    
    let qazToShala: [String: [String]] = [
        "ә": ["а"],
        "ғ": ["г"],
        "қ": ["к"],
        "ң": ["н"],
        "ө": ["о"],
        "ұ": ["у"],
        "ү": ["у"],
        "һ": ["х"],
        "і": ["и", "ы"]
    ]

    init() {}

    func generateEndings(for word: String) -> [String] {
        return Form.allCases.map { form in
            let posessives = Quantity.allCases.map { quantity in
                let service = PossessiveService(possessive: form, quantitative: quantity)
                return service.process(text: word)
            }

            let quantitatives = Quantity.allCases.map { quantity in
                let service = QuantitativeService(quantitative: quantity)
                return service.process(text: word)
            }
            return posessives + quantitatives
        }.flatMap { $0 }
    }

    // TODO: generate data for cases with
    // endings like "қазақ" and "қазағым"

    /// if user typed "казагым" input root must be "қазақ" not "қазағ"
    func generateShalaqazaqDatasetForEndings(for root: String) -> [String: String] {
        var shalaqazaqDataset: [String: String] = [:]
        generateEndings(for: root)
            .forEach { wordWithEnding in
                let shalaEndigns = generateShalaWords(for: wordWithEnding, targetShala: "", currentIndex: 0)
                shalaEndigns.forEach { shalaEnding in
                    shalaqazaqDataset[shalaEnding] = wordWithEnding
                }
            }
        return shalaqazaqDataset
    }

    private func generateShalaWords(for word: String, targetShala: String, currentIndex: Int) -> [String] {
        var targetShala = targetShala
        for index in (currentIndex ..< word.count) {
            let letter = String(word[index])
            guard let shalaLetters = qazToShala[letter] else {
                targetShala.append(letter)
                continue
            }
            var shalaWords = [String]()
            shalaLetters.forEach { shalaLetter in
                targetShala.append(shalaLetter)
                let generatedShala = generateShalaWords(for: word, targetShala: targetShala, currentIndex: index + 1)
                targetShala.removeLast()
                shalaWords.append(contentsOf: generatedShala)
            }
            return shalaWords
        }
        return [targetShala]
    }

}

func generateTazaOutput(for input: String, root: String) -> String {
    let shalaDataset = QazaqEndingsGenerator().generateShalaqazaqDatasetForEndings(for: root)

    for i in (2..<input.count).reversed() {
        let subString = input[0..<i]
    }

    return shalaDataset[input] ?? input
}


let root = "ілім"
let input = "ылимимиз"

//PossessiveService(possessive: .first, quantitative: .singular).process(text: root)
//print(QazaqEndingsGenerator().generateEndings(for: root))
print(generateTazaOutput(for: input, root: root))
