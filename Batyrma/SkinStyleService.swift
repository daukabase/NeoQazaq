//
//  SkinStyleService.swift
//  Batyrma
//
//  Draws the keyboard in the skin chosen in the app (KeyboardSkin). Classic keeps
//  KeyboardKit's standard iOS look.
//

import KeyboardKit
import SwiftUI
import QazaqFoundation

final class SkinStyleService: KeyboardStyle.StandardStyleService {
    let skin: KeyboardSkin

    init(keyboardContext: KeyboardContext, skin: KeyboardSkin) {
        self.skin = skin
        super.init(keyboardContext: keyboardContext)
    }

    override var backgroundStyle: Keyboard.Background {
        guard let colors = skin.background else { return super.backgroundStyle }
        return colors.count > 1 ? .verticalGradient(colors) : .color(colors[0])
    }

    override var foregroundColor: Color? {
        skin.isSystem ? super.foregroundColor : skin.text
    }

    override func buttonBackgroundColor(for action: KeyboardAction, isPressed: Bool) -> Color {
        guard !skin.isSystem, !Self.keepsStandardLook(action) else {
            return super.buttonBackgroundColor(for: action, isPressed: isPressed)
        }
        if action.isPrimaryAction { return isPressed ? skin.key : skin.primary }
        if action.isSystemAction { return isPressed ? skin.key : skin.systemKey }
        return isPressed ? skin.systemKey : skin.key
    }

    /// Colour scheme for the suggestion bar. Its text is `.primary`, which follows the host app's
    /// light/dark mode, so a light skin (Көк) in a dark app got white text on light keys. Match the
    /// skin instead: dark key text → light scheme. nil (system skins) keeps the system behaviour.
    var toolbarColorScheme: ColorScheme? {
        guard !skin.isSystem else { return nil }
        var white: CGFloat = 0, alpha: CGFloat = 0
        UIColor(skin.text).getWhite(&white, alpha: &alpha)
        return white < 0.5 ? .light : .dark
    }

    /// The space bar carries the sponsor credit (or invites a sponsor) instead of "space".
    override func buttonText(for action: KeyboardAction) -> String? {
        action == .space ? KeyboardSponsor.spaceBarLabel : super.buttonText(for: action)
    }

    override func buttonForegroundColor(for action: KeyboardAction, isPressed: Bool) -> Color {
        let color = skinForegroundColor(for: action, isPressed: isPressed)
        // The space bar text stays quiet: dimmed, so the keys remain the focus.
        return action == .space ? color.opacity(0.55) : color
    }

    private func skinForegroundColor(for action: KeyboardAction, isPressed: Bool) -> Color {
        guard !skin.isSystem, !Self.keepsStandardLook(action) else {
            return super.buttonForegroundColor(for: action, isPressed: isPressed)
        }
        if action.isPrimaryAction && !isPressed { return skin.primaryText }
        return skin.text
    }

    /// Invisible and margin keys must stay transparent.
    private static func keepsStandardLook(_ action: KeyboardAction) -> Bool {
        switch action {
        case .none, .characterMargin, .emoji: return true
        default: return false
        }
    }
}
