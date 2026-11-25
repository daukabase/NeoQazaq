//
//  GlobalConstants.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 05.05.2024.
//

public enum GlobalConstants {
    public static let appName = "Batyrma"
    public static let appVersion = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version ?? "1.0.0"
    }()
    /// App Store page, added to shared stats. TODO: set to https://apps.apple.com/app/id<APP_ID>.
    public static let appStoreURL: URL? = nil
    public static let neoQazaqKeyboardExtensionIdentifier = "com.almagambetov.daulet.qazaqsha.Qazaqsha.NeoQazaq"

    public static var isKeyboardExtensionEnabled: Bool {
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return false
        }
        
        return keyboards.contains(neoQazaqKeyboardExtensionIdentifier)
    }
}
