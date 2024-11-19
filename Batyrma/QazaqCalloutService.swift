//
//  QazaqCalloutService.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 19.11.2024.
//

import KeyboardKit

class QazaqCalloutService: CalloutService {
    func triggerFeedbackForSelectionChange() { }
    
    /// Get callout actions for the provided action.
    open func calloutActions(
        for action: KeyboardAction
    ) -> [KeyboardAction] {
        switch action {
        case .character(let char): return calloutActions(for: char)
        default: return []
        }
    }
    
    /// Get callout actions for the provided character.
    open func calloutActions(
        for char: String
    ) -> [KeyboardAction] {
        let charValue = char.lowercased()
        let result = calloutActionString(for: charValue)
        let string = char.isUppercasedWithLowercaseVariant ? result.uppercased() : result
        return string.map { .character(String($0)) }
    }
    
    func calloutActionString(for char: String) -> String {
        switch char {
        case "у": return "уұү"
        case "к": return "кқ"
        case "е": return "её"
        case "н": return "нң"
        case "г": return "гғ"
        case "х": return "хһ"
        case "ы": return "ыі"
        case "а": return "аә"
        case "о": return "оө"
        case "и": return "иі"
        case "ь": return "ьъ"
        case "б": return String("брат".reversed())
            
        case "0": return "0°"
            
        case "-": return "-–—•"
        case "/": return "/\\"
        case "$": return "$₽¥€¢£₩"
        case "&": return "&§"
        case "”": return "\"„“”«»"
        case ".": return ".…"
        case "?": return "?¿"
        case "!": return "!¡"
        case "’": return "'’‘`"
            
        case "%": return "%‰"
        case "=": return "=≠≈"
            
        default: return ""
        }
    }
}

extension InputSet {
    static var russian: InputSet {
        .init(rows: [
            .init(chars: "йцукенгшщзх"),
            .init(chars: "фывапролджэ"),
            .init(phone: "ячсмитьбю", pad: "ячсмитьбю,.")
        ])
    }
}
