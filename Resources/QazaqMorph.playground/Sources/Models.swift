import Foundation

public struct Ending: Codable {
    public let plural: Plural
    public let belongs: Belongs
    public let personal: Personal
    public let cases: Cases
}

public struct Plural: Codable {
    public let solid, soft: [String]
}

public struct Belongs: Codable {
    public let vowels, consonants: VowelConsonant
}

public struct VowelConsonant: Codable {
    public let solid, soft: [[String]]
}

public struct Personal: Codable {
    public let singular, plural: PersonalType
}

public struct PersonalType: Codable {
    public let solid, soft: [[String]]
}

public struct Cases: Codable {
    public let nominative: [String]
    public let genitive, dativeDirectional, accusative, locative, ablative: CaseType
    public let instrumental: [String]
}

public struct CaseType: Codable {
    public let solid, soft: [String]
}

public enum Constants {
    public static let qazaqEndings = Ending(
        plural: Plural(
            solid: ["лар", "дар", "тар"],
            soft: ["лер", "дер", "тер"]
        ),
        belongs: Belongs(
            vowels: VowelConsonant(
                solid: [
                    ["м", "мыз"],
                    ["ң", "ңыз"],
                    ["сы"]
                ],
                soft: [
                    ["м", "міз"],
                    ["ң", "ңіз"],
                    ["сі"]
                ]
            ),
            consonants: VowelConsonant(
                solid: [
                    ["ым", "мыз"],
                    ["ың", "ыңыз"],
                    ["ы"]
                ],
                soft: [
                    ["ім", "іміз"],
                    ["ің", "іңіз"],
                    ["і"]
                ]
            )
        ),
        personal: Personal(
            singular: PersonalType(
                solid: [
                    ["мын", "пын", "бын"],
                    ["сың", "сыз"],
                    [""]
                ],
                soft: [
                    ["мін", "пін", "бін"],
                    ["сің", "сіз"],
                    [""]
                ]
            ),
            plural: PersonalType(
                solid: [
                    ["мыз", "пыз", "быз"],
                    ["сыңдар", "сыздар"],
                    [""]
                ],
                soft: [
                    ["міз", "піз", "біз"],
                    ["сіңдер", "сіздер"],
                    [""]
                ]
            )
        ),
        cases: Cases(
            nominative: [],
            genitive: CaseType(
                solid: ["ның", "дың", "тың"],
                soft: ["нің", "дің", "тің"]
            ),
            dativeDirectional: CaseType(
                solid: ["ға", "қа"],
                soft: ["ге", "ке"]
            ),
            accusative: CaseType(
                solid: ["ны", "ды", "ты"],
                soft: ["ні", "ді", "ті"]
            ),
            locative: CaseType(
                solid: ["да", "та"],
                soft: ["де", "те"]
            ),
            ablative: CaseType(
                solid: ["дан", "тан", "нан"],
                soft: ["ден","тен", "нен"]
            ),
            instrumental: ["мен", "бен", "пен"]
        )
    )
}
