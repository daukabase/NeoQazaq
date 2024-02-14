//
//  QuantitativeService.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 14.02.2024.
//


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
