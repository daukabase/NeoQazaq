//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

let kazakhUniqueCharacters = ["ә", "ғ", "қ", "ң", "ө", "ұ", "ү", "һ", "і"]

let qazToShala = [
    "ә": "а",
    "ғ": "г",
    "қ": "к",
    "ң": "н",
    "ө": "о",
    "ұ": "у",
    "ү": "у",
    "һ": "х",
    "і": "и"
]


func kk_KZDicListdatasetFileURL() -> [String] {
    if let fileURL = Bundle.main.url(forResource: "kk_KZ", withExtension: "txt") {
        do {
            let data = try Data(contentsOf: fileURL)
            let textData = String(data: data, encoding: .utf16)!
            return textData.split(separator: "\n").map { String($0) }
        } catch {
            // Handle errors
            print("Error reading or parsing the JSON file: \(error.localizedDescription)")
        }
    } else {
        print("JSON file not found in playground resources.")
    }
    return []
}



func qazWordsJsonDatasetFileURL() -> [String: String] {
    if let fileURL = Bundle.main.url(forResource: "QazaqWordsDatabase", withExtension: "json") {
        do {
            // Read the file content
            let data = try Data(contentsOf: fileURL)
            
            // Decode the JSON data
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([String: String].self, from: data)
            
            return jsonData
        } catch {
            // Handle errors
            print("Error reading or parsing the JSON file: \(error.localizedDescription)")
        }
    } else {
        print("JSON file not found in playground resources.")
    }
    return [:]
}

func shalaqazaqJsonDatasetFileURL() -> [String: String]{
    if let fileURL = Bundle.main.url(forResource: "ShalaqazaqDataset", withExtension: "json") {
        do {
            // Read the file content
            let data = try Data(contentsOf: fileURL)
            
            // Decode the JSON data
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([String: String].self, from: data)
            
            return jsonData
        } catch {
            // Handle errors
            print("Error reading or parsing the JSON file: \(error.localizedDescription)")
        }
    } else {
        print("JSON file not found in playground resources.")
    }
    return [:]
}

func datasetFileURL(filename: String, ext: String) -> [String] {
    if let fileURL = Bundle.main.url(forResource: filename, withExtension: ext) {
        do {
            let data = try Data(contentsOf: fileURL)
            let textData = String(data: data, encoding: .utf8)!
            return textData.split(separator: "\n").map { String($0) }
        } catch {
            // Handle errors
            print("Error reading or parsing the JSON file: \(error.localizedDescription)")
        }
    } else {
        print("JSON file not found in playground resources.")
    }
    return []
}
func qazWordsListdatasetFileURL() -> [String] {
    datasetFileURL(filename: "QazaqWordsDatabase", ext: "txt")
}

func rusWordsListdatasetFileURL() -> [String] {
    datasetFileURL(filename: "rusWords", ext: "txt")
}

func replaceQazaqCharsWithShalaqazaqIfNeeded(in word: String) -> String {
    word.map {
        let char = String($0)
        if let shalaQazChar = qazToShala[char] {
            return shalaQazChar
        } else {
            return char
        }
    }.joined()
}

//var json = datasetFileURL()

func convertToCorrect(json: [String: String]) -> [String: String] {
    let updated = json
        .filter {
            $0.key != $0.value
        }
        .map { (key, value) -> (String, String) in
            let hasQazChar = key.contains(where: { kazakhUniqueCharacters.contains(String($0)) })
            if hasQazChar {
                return (replaceQazaqCharsWithShalaqazaqIfNeeded(in: key), key)
            } else {
                return (replaceQazaqCharsWithShalaqazaqIfNeeded(in: key), value)
            }
        }
        .filter {
            let hasQazChar = $0.1.contains(where: { kazakhUniqueCharacters.contains(String($0)) })
            return hasQazChar
        }

    var updatedJson = [String: String]()

    updated.forEach { (key, value) in
        updatedJson[key] = value
    }
    let finalSortedJson = updatedJson.sorted { $0.key < $1.key }
        .reduce([String: String]()) { partialResult, pair in
            var res = partialResult
            res[pair.key] = pair.value
            return res
        }
    return finalSortedJson
}

func printAsJsonString(data: Any) {
    do {
        // Convert your dictionary to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
        
    } catch {
        // Handle errors
    }
}


extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

func isEnglishLetter(_ character: Character) -> Bool {
    let englishLetters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return englishLetters.contains(character)
}


var shalaDataset = [String: [String: Double]]()

var wordsDataset = qazWordsListdatasetFileURL()

wordsDataset.forEach { word in
    let shala = replaceQazaqCharsWithShalaqazaqIfNeeded(in: word)
    if word != shala {
        var hasShala = false
        if !shalaDataset.keys.contains(shala) {
            shalaDataset[shala] = [:]
        } else {
//            print("found duplicate: \(word)")
            hasShala = true
        }
        shalaDataset[shala]?[word] = Double(hasShala ? 0.9 : 1.0)
    }
}


wordsDataset.forEach { word in
    if shalaDataset.keys.contains(word) {
        print(word)
    }
}



//let russianCommonWords = rusWordsListdatasetFileURL()
//russianCommonWords.forEach { rusWord in
//    if shalaDataset[rusWord] != nil {
//        print("RUS DUPLICATE: \(rusWord)")
//    }
//}

printAsJsonString(data: shalaDataset)
//print(pureWords)
