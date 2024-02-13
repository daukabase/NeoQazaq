import Foundation

// Assuming `vowels`, `consonants`, and `endings` are loaded into these variables somehow
var vowels: [String: [String]] = [
    "solid": ["а", "о", "ұ", "ы", "у"],
    "soft": ["ә", "е", "ө", "ү", "і", "и"],
    "both": ["у", "и"]
]
var consonants: [String: [String]] = [
    "unvoiced": ["п", "к", "қ", "т", "с", "ф", "х", "ц", "ч", "ш", "щ", "һ"],
    "voiced": ["б","в", "г", "ғ", "д", "ж", "з"],
    "sonor": ["р", "л", "м", "н", "ң", "у", "й"]
]
var endings = Constants.qazaqEndings


// Helper function to flatten and unique an array
func flattenAndUnique(_ array: [[String]]) -> [String] {
    let flatArray = array.flatMap { $0 }
    return Array(Set(flatArray))
}


let allVowels = flattenAndUnique(Array(vowels.values))
let vowelsSoft = vowels["soft"] ?? []
let vowelsSolid = vowels["solid"] ?? []
let vowelsBoth = vowels["both"] ?? []

let allConsonants = flattenAndUnique(Array(consonants.values))
let consonantsUnvoiced = consonants["unvoiced"] ?? []
let consonantsVoiced = consonants["voiced"] ?? []
let consonantsSonor = consonants["sonor"] ?? []

func getKeyByValue(object: [String: [String]], char: String) -> String? {
    for (key, value) in object {
        if value.contains(char) {
            return key
        }
    }
    return nil
}

func getLastIndex(str: String, array: [String]) -> Int {
    let characters = Array(str)
    for (index, char) in characters.enumerated().reversed() {
        if array.contains(String(char)) {
            return index
        }
    }
    return -1
}

func getVowelType(_ str: String) -> String {
    let allVowelsArray = allVowels
    let indexVowel = getLastIndex(str: str, array: allVowelsArray)

    if indexVowel > -1 {
        let charAtVowel = String(str[str.index(str.startIndex, offsetBy: indexVowel)])
        if let type = getKeyByValue(object: vowels, char: charAtVowel) {
            if vowelsBoth.contains(charAtVowel) {
                let nextIndexVowel = getLastIndex(str: String(str[..<str.index(str.startIndex, offsetBy: indexVowel)]), array: allVowelsArray)
                if indexVowel != nextIndexVowel && nextIndexVowel > -1 {
                    return getKeyByValue(object: vowels, char: String(str[str.index(str.startIndex, offsetBy: nextIndexVowel)])) ?? ""
                }
            }
            return type
        }
    }
    return ""
}

func pluralize(_ str: String) -> String {
    let type = getVowelType(str.lowercased())
    let endingsForType = type == "soft" ? endings.plural.soft : endings.plural.solid

    guard !endingsForType.isEmpty else { return str }

    let newStr = str + (endingsForType.first ?? "")
    return newStr
}

func belong(_ str: String, side: Int = 1, formal: Bool = false) -> String {
    let type = getVowelType(str.lowercased())
    
    // Assuming a method to determine if the last char is a vowel or consonant for simplicity
    let isLastCharVowel = /* Determine based on your data */
    
    let endingsForType = isLastCharVowel ? endings.belongs.vowels : endings.belongs.consonants
    let selectedEndings = type == "soft" ? endingsForType.soft : endingsForType.solid
    
    // Selecting the appropriate ending based on `side` and `formal` might require further adjustment
    // This is a simplified example
    let ending = selectedEndings.first ?? [""] // Adjust based on your logic
    
    return str + (ending.first ?? "")
}

func decline(_ str: String, declension: String) -> String {
    let type = getVowelType(str.lowercased())
    
    // Select the correct case based on the `declension` parameter
    let caseEndings: [String]
    switch declension {
    case "nominative":
        caseEndings = endings.cases.nominative
    case "genitive":
        caseEndings = type == "soft" ? endings.cases.genitive.soft : endings.cases.genitive.solid
    // Add other cases here
    default:
        caseEndings = []
    }
    
    guard !caseEndings.isEmpty else { return str }
    
    return str + (caseEndings.first ?? "")
}
