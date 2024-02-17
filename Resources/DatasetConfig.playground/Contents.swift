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


func json(filename: String) -> [String: String] {
    if let fileURL = Bundle.main.url(forResource: filename, withExtension: "json") {
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

let shalaqazaqJsonDatasetFileURL = json(filename: "ShalaqazaqDataset")
let qazaqWordsList: [String] = datasetFileURL(filename: "qazaqWordsList", ext: "txt")
let rusMostCommonWordsDataset: [String] = datasetFileURL(filename: "rusWords", ext: "txt")

qazaqWordsList.filter { $0.count <= 2 }.forEach {
    print($0)
}




//let russianCommonWords = rusWordsListdatasetFileURL()
//russianCommonWords.forEach { rusWord in
//    if shalaDataset[rusWord] != nil {
//        print("RUS DUPLICATE: \(rusWord)")
//    }
//}
