//
//  CyrillicKeyboardLayout.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 19.11.2024.
//

import KeyboardKit

final class CyrillicKeyboardLayout {

    static func get(for layout: KeyboardKit.KeyboardLayout) -> KeyboardKit.KeyboardLayout {
        var layout = layout
        var rows = layout.itemRows

        // KeyboardKit is expected to hand back at least 3 rows for the layouts we customize.
        // Guard instead of force-indexing so an unexpected layout (future KeyboardKit change,
        // device/locale edge case) degrades gracefully instead of crashing the extension.
        guard rows.count >= 3 else {
            return layout
        }

        var row_1 = layout.itemRows[0]
        var row_2 = layout.itemRows[1]
        var row_3 = layout.itemRows[2]

        guard let next = row_1.first else {
            return layout
        }

        for i in 0..<row_1.count {
            row_1[i].size = .init(width: .available, height: next.size.height)
        }

        for j in 0..<row_2.count {
            row_2[j].size = .init(width: .available, height: next.size.height)
        }

        for j in 0..<row_3.count {
            switch row_3[j].action {
            case .shift, .backspace:
                row_3[j].size = .init(width: .input, height: next.size.height)
            default:
                continue
            }
        }

        row_3.removeAll(where: {$0.action == .characterMargin("я") ||
            $0.action == .characterMargin("ю") ||
            $0.action == .characterMargin("Ю") ||
            $0.action == .characterMargin("Я")
        })

        rows[0] = row_1
        rows[1] = row_2
        rows[2] = row_3

        layout.itemRows = rows
        return layout
    }

}
