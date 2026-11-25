//
//  KeyboardSkin.swift
//  QazaqFoundation
//
//  Keyboard skins: colours for the keyboard background and keys. Shared by the app (picker,
//  purchases) and the keyboard (rendering). The app writes the chosen skin and the purchased
//  products to the app group; the keyboard only reads them, so skins work without Full Access.
//  Colours and gradients only (no images), so skins cost the keyboard no memory.
//

import SwiftUI

public struct KeyboardSkin: Identifiable, Equatable {
    public enum Availability: Equatable {
        case free
        /// Unlocked by a one-time purchase (a pack can unlock several skins).
        case paid(productID: String)
        /// Limited edition: sold only in `month` (1–12); owners keep it forever.
        case limited(productID: String, month: Int)
    }

    public let id: String
    public let name: String
    public let availability: Availability
    /// Background gradient, top to bottom; nil keeps the system keyboard look.
    public let background: [Color]?
    public let key: Color
    public let systemKey: Color
    public let text: Color
    public let primary: Color
    public let primaryText: Color

    public var productID: String? {
        switch availability {
        case .free: return nil
        case .paid(let id), .limited(let id, _): return id
        }
    }

    /// Follows the system keyboard (light/dark) instead of fixed colours.
    public var isSystem: Bool { background == nil }
}

// MARK: - Catalogue

public extension KeyboardSkin {
    static let productPrefix = "com.almagambetov.daulet.qazaqsha.skins."
    /// Дала, Көк Тәңір, Ақ боз, Алтын.
    static let steppePackID = productPrefix + "steppe"
    /// Наурыз 2027 limited edition, sold in March.
    static let nauryzID = productPrefix + "nauryz2027"

    static let classic = KeyboardSkin(
        id: "classic", name: "Classic", availability: .free, background: nil,
        key: Color(hex: 0xFFFFFF), systemKey: Color(hex: 0xABB0BA), text: Color(hex: 0x000000),
        primary: Color(hex: 0x007AFF), primaryText: .white
    )
    // Apple-style palettes: quiet, desaturated tones close to the system keyboard, one accent on Return.
    static let tun = KeyboardSkin(
        id: "tun", name: "Түн", availability: .free,
        background: [Color(hex: 0x1C1F26), Color(hex: 0x121419)],
        key: Color(hex: 0x353943), systemKey: Color(hex: 0x24272E), text: Color(hex: 0xF2F3F5),
        primary: Color(hex: 0x0A84FF), primaryText: .white
    )
    static let kok = KeyboardSkin(
        id: "kok", name: "Көк", availability: .free,
        background: [Color(hex: 0xDDE5EE), Color(hex: 0xCBD5E1)],
        key: Color(hex: 0xFFFFFF), systemKey: Color(hex: 0xADBACB), text: Color(hex: 0x111C2B),
        primary: Color(hex: 0x1F3A5F), primaryText: .white
    )
    static let dala = KeyboardSkin(
        id: "dala", name: "Дала", availability: .paid(productID: steppePackID),
        background: [Color(hex: 0xE8E0D2), Color(hex: 0xD6C8B1)],
        key: Color(hex: 0xFBF8F2), systemKey: Color(hex: 0xC2B297), text: Color(hex: 0x2E261C),
        primary: Color(hex: 0x8A6A3E), primaryText: .white
    )
    static let tanir = KeyboardSkin(
        id: "tanir", name: "Көк Тәңір", availability: .paid(productID: steppePackID),
        background: [Color(hex: 0x14293B), Color(hex: 0x0B1A27)],
        key: Color(hex: 0x23394D), systemKey: Color(hex: 0x182C3E), text: Color(hex: 0xEAF3F9),
        primary: Color(hex: 0x6CB8DC), primaryText: Color(hex: 0x07202E)
    )
    static let akboz = KeyboardSkin(
        id: "akboz", name: "Ақ боз", availability: .paid(productID: steppePackID),
        background: [Color(hex: 0xF4F4F2), Color(hex: 0xE5E5E1)],
        key: Color(hex: 0xFFFFFF), systemKey: Color(hex: 0xCECEC8), text: Color(hex: 0x1C1C1E),
        primary: Color(hex: 0x1C1C1E), primaryText: .white
    )
    static let altyn = KeyboardSkin(
        id: "altyn", name: "Алтын", availability: .paid(productID: steppePackID),
        background: [Color(hex: 0x161514), Color(hex: 0x0A0A0A)],
        key: Color(hex: 0x2A2825), systemKey: Color(hex: 0x1E1D1B), text: Color(hex: 0xE9DCBC),
        primary: Color(hex: 0xC9A86A), primaryText: Color(hex: 0x161514)
    )
    static let nauryz = KeyboardSkin(
        id: "nauryz", name: "Наурыз", availability: .limited(productID: nauryzID, month: 3),
        background: [Color(hex: 0xF2E9EB), Color(hex: 0xE2ECE2)],
        key: Color(hex: 0xFFFFFF), systemKey: Color(hex: 0xD3C5C9), text: Color(hex: 0x2B2427),
        primary: Color(hex: 0x5E8C61), primaryText: .white
    )

    static let all: [KeyboardSkin] = [classic, tun, kok, dala, tanir, akboz, altyn, nauryz]

    static var productIDs: Set<String> { Set(all.compactMap(\.productID)) }

    static func with(id: String?) -> KeyboardSkin {
        all.first { $0.id == id } ?? classic
    }
}

// MARK: - Shared state (app group)

public extension KeyboardSkin {
    static let selectedSkinKey = "keyboardSkinId"
    static let ownedProductsKey = "ownedSkinProducts"

    /// The skin the keyboard should draw: the chosen one if it's free or owned, else Classic
    /// (e.g. after a refund).
    static func current(defaults: UserDefaults = .localAppGroup) -> KeyboardSkin {
        let skin = with(id: defaults.string(forKey: selectedSkinKey))
        guard let productID = skin.productID else { return skin }
        let owned = defaults.stringArray(forKey: ownedProductsKey) ?? []
        return owned.contains(productID) ? skin : classic
    }

    /// Whether a limited skin can be bought right now.
    func isOnSale(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        switch availability {
        case .free, .paid: return true
        case .limited(_, let month): return calendar.component(.month, from: now) == month
        }
    }
}

public extension Color {
    /// 0xRRGGBB.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The keyboard's sponsor, credited on the space bar as "<brand> қолдауымен" ("supported by <brand>").
/// Plain text only: App Review 4.4.1 doesn't let a keyboard open other apps or repurpose keys, so
/// it isn't a link. It ships in the build (no network needed, works without Full Access).
public enum KeyboardSponsor {
    /// Set ONLY once a sponsor agreement is signed; keep it short (it shares the space bar).
    /// nil = no sponsor yet: the space bar invites one instead.
    public static let brandName: String? = nil

    /// Space bar text: the sponsor credit, or "Be a sponsor" while the spot is free.
    public static var spaceBarLabel: String {
        brandName.map { "\($0) қолдауымен" } ?? "Демеуші болыңыз"
    }
}
