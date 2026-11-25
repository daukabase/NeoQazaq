//
//  QazaqActionHandler.swift
//  Batyrma
//
//  Undo for autocorrect (specs/01-fix-spec.md C2): the first backspace right after an
//  autocorrection restores what the user typed, remembers the refusal so the same correction
//  isn't applied again, and learns the typed word.
//

import KeyboardKit
import WordSuggestionsEngine
import QazaqFoundation

final class QazaqActionHandler: KeyboardAction.StandardActionHandler {
    private let store: PersonalStore
    private var lastAutocorrection: (original: String, replacement: String)?

    init(controller: KeyboardController, store: PersonalStore) {
        self.store = store
        super.init(controller: controller)
    }

    override func tryApplyAutocorrectSuggestion(before gesture: Keyboard.Gesture, on action: KeyboardAction) {
        let original = keyboardContext.textDocumentProxy.currentWordPreCursorPart
        let suggestion = autocompleteContext.suggestions.first { $0.isAutocorrect }
        let willApply = suggestion != nil && shouldApplyAutocorrectSuggestion(before: gesture, on: action)
        super.tryApplyAutocorrectSuggestion(before: gesture, on: action)
        if willApply, let original, let suggestion, original != suggestion.text {
            lastAutocorrection = (original, suggestion.text)
            // Home-screen stats (numbers only). The app group is writable only with Full Access.
            if keyboardContext.hasFullAccess {
                TypingStats.recordCorrection(original: original, replacement: suggestion.text)
            }
        }
    }

    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction, replaced: Bool) {
        if gesture == .press, action == .backspace, revertLastAutocorrection() {
            return // this backspace was used up by the undo
        }
        // Any other key closes the undo window. The space release that triggered the correction
        // sets it again inside super.handle, so it survives until the next key.
        if gesture == .press || action != .space {
            lastAutocorrection = nil
        }
        super.handle(gesture, on: action, replaced: replaced)
    }

    /// KeyboardKit would otherwise "ignore" whatever word is under the cursor on many backspaces
    /// (even while just fixing a typo). Undo is handled explicitly above instead.
    override func tryAutocompleteIgnoreCurrentWord(before gesture: Keyboard.Gesture, on action: KeyboardAction) {}

    private func revertLastAutocorrection() -> Bool {
        guard let last = lastAutocorrection else { return false }
        lastAutocorrection = nil
        let proxy = keyboardContext.textDocumentProxy
        let correctedText = last.replacement + " "
        guard proxy.documentContextBeforeInput?.hasSuffix(correctedText) == true else { return false }

        for _ in 0..<correctedText.count { proxy.deleteBackward() }
        proxy.insertText(last.original) // "өл␣" → "ол", cursor right after it
        store.reject(typed: last.original, candidate: last.replacement)
        store.learn(last.original)
        return true
    }
}
