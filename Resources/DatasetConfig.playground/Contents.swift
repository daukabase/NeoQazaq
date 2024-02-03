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

func datasetFileURL() -> [String: String]{
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

var json = datasetFileURL()

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

do {
    // Convert your dictionary to JSON data
    let jsonData = try JSONSerialization.data(withJSONObject: finalSortedJson, options: .prettyPrinted)
    
    // Get the playground's shared directory URL
    let playgroundSharedDirectoryURL = playgroundSharedDataDirectory
    
    let fileURL = Bundle.main.url(forResource: "ShalaqazaqDataset", withExtension: "json")!
    // Create a file URL for the new file in the playground's shared directory
//    let fileURL = playgroundSharedDirectoryURL.appendingPathComponent("ShalaqazaqDataset.json")
    
    // Write the JSON data to the file
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
    
} catch {
    // Handle errors
    
}
