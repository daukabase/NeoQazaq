//
//  CyrillicService.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 19.11.2024.
//

import KeyboardKit

final class CyrillicService: KeyboardLayout.DeviceBasedService {
    override init(
        alphabeticInputSet: InputSet = .qwerty,
        numericInputSet: InputSet = .numeric(currency: "$"),
        symbolicInputSet: InputSet = .symbolic(currencies: ["€", "£", "¥"])
    ) {
        super.init(
            alphabeticInputSet: alphabeticInputSet,
            numericInputSet: numericInputSet,
            symbolicInputSet: symbolicInputSet
        )
        localeKey = KeyboardLocale.kazakh.id
    }

    override func keyboardLayout(
        for context: KeyboardContext
    ) -> KeyboardLayout {
        let service = keyboardLayoutService(for: context)
        let layout = service.keyboardLayout(for: context)
        return CyrillicKeyboardLayout.get(for: layout)
    }
}
