//
//  String+.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation

public extension String {
    /// Get the word or fragment at the start of the string.
    var wordFragmentAtStart: String {
        var reversed = String(self.reversed())
        var result = ""
        while let char = reversed.popLast() {
            guard shouldIncludeCharacterInCurrentWord(char) else { return result }
            result.append(char)
        }
        return result
    }
    
    /// Get the word or fragment at the end of the string.
    var wordFragmentAtEnd: String {
        var string = self
        var result = ""
        while let char = string.popLast() {
            guard shouldIncludeCharacterInCurrentWord(char) else { return result }
            result.insert(char, at: result.startIndex)
        }
        return result
    }

    func shouldIncludeCharacterInCurrentWord(_ character: Character) -> Bool {
        !"\(character)".isWordDelimiter
    }
}

public extension String {
    
    /// A list of mutable, western word delimiters.
    static var wordDelimiters = "!.?,;:()[]{}<>".map(String.init) + [" ", .newline]
    
    /// Whether or not this is a western word delimiter.
    var isWordDelimiter: Bool {
        Self.wordDelimiters.contains(self)
    }
}

public extension String {

    /// A carriage return character.
    static let carriageReturn = "\r"

    /// A new line character.
    static let newline = "\n"

    /// A space character.
    static let space = " "

    /// A tab character.
    static let tab = "\t"

    /// A zero width space character used in some RTL languages.
    static let zeroWidthSpace = "\u{200B}"
}
