//
//  UITextDocumentProxy+.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import UIKit

public extension UITextDocumentProxy {
    /// Replace the current word with a replacement text.
    func replaceCurrentWord(with replacement: String) {
        guard let word = currentWord else { return }
        let offset = currentWordPostCursorPart?.count ?? 0
        adjustTextPosition(byCharacterOffset: offset)
        deleteBackward(times: word.count)
        insertText(replacement)
    }

    func deleteBackward(times: Int) {
        (0 ..< times).forEach { _ in deleteBackward() }
    }

    /// The word that is at the current cursor location.
    var currentWord: String? {
        let pre = currentWordPreCursorPart
        let post = currentWordPostCursorPart
        if pre == nil && post == nil { return nil }
        return (pre ?? "") + (post ?? "")
    }
    
    /// The part of the current word that is before the cursor.
    var currentWordPreCursorPart: String? {
        documentContextBeforeInput?.wordFragmentAtEnd
    }
    
    /// The part of the current word that is after the cursor.
    var currentWordPostCursorPart: String? {
        documentContextAfterInput?.wordFragmentAtStart
    }
}
