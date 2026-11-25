//
//  SkinStore.swift
//  Qazaqsha
//
//  Keyboard skins: selection and purchases (StoreKit 2, one-time purchases). The products
//  must exist in App Store Connect (see KeyboardSkin.productIDs); until they do, paid skins
//  show "Soon". The chosen skin and the owned products go to the app group for the keyboard.
//  Events: skin_selected, skin_purchase_started, skin_purchased, skin_purchase_cancelled.
//

import SwiftUI
import StoreKit
import QazaqFoundation

@MainActor
final class SkinStore: ObservableObject {
    static let shared = SkinStore()

    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var ownedProductIDs: Set<String>
    @Published private(set) var selectedID: String
    @Published private(set) var purchasingProductID: String?

    private let defaults = UserDefaults.localAppGroup
    private var didLoad = false
    private var updatesTask: Task<Void, Never>?

    private init() {
        ownedProductIDs = Set(defaults.stringArray(forKey: KeyboardSkin.ownedProductsKey) ?? [])
        selectedID = KeyboardSkin.current(defaults: defaults).id
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    deinit { updatesTask?.cancel() }

    var selected: KeyboardSkin { KeyboardSkin.with(id: selectedID) }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        if let loaded = try? await Product.products(for: KeyboardSkin.productIDs) {
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        }
        await refreshEntitlements()
    }

    func isUnlocked(_ skin: KeyboardSkin) -> Bool {
        guard let productID = skin.productID else { return true }
        return ownedProductIDs.contains(productID)
    }

    /// Price to show on a locked skin, or nil when it can't be bought now.
    func price(for skin: KeyboardSkin) -> String? {
        guard let productID = skin.productID, skin.isOnSale() else { return nil }
        return products[productID]?.displayPrice
    }

    /// Tap on a skin: select it if unlocked, otherwise start the purchase.
    func tapped(_ skin: KeyboardSkin) async {
        if isUnlocked(skin) {
            select(skin)
        } else {
            await buy(skin)
        }
    }

    func select(_ skin: KeyboardSkin) {
        guard isUnlocked(skin), skin.id != selectedID else { return }
        selectedID = skin.id
        defaults.set(skin.id, forKey: KeyboardSkin.selectedSkinKey)
        UISelectionFeedbackGenerator().selectionChanged()
        track("skin_selected", skin)
    }

    func buy(_ skin: KeyboardSkin) async {
        guard let productID = skin.productID, let product = products[productID], skin.isOnSale(),
              purchasingProductID == nil else { return }
        purchasingProductID = productID
        defer { purchasingProductID = nil }
        track("skin_purchase_started", skin)
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
                if isUnlocked(skin) {
                    track("skin_purchased", skin)
                    select(skin)
                }
            case .userCancelled, .pending:
                track("skin_purchase_cancelled", skin)
            @unknown default:
                break
            }
        } catch {
            track("skin_purchase_cancelled", skin)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        setOwned(owned)
    }

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        var owned = ownedProductIDs
        if transaction.revocationDate == nil {
            owned.insert(transaction.productID)
        } else {
            owned.remove(transaction.productID)
        }
        setOwned(owned)
        await transaction.finish()
    }

    private func setOwned(_ owned: Set<String>) {
        ownedProductIDs = owned
        defaults.set(Array(owned), forKey: KeyboardSkin.ownedProductsKey)
        // A refunded skin falls back to Classic, like in the keyboard.
        if !isUnlocked(selected) {
            selectedID = KeyboardSkin.classic.id
            defaults.set(selectedID, forKey: KeyboardSkin.selectedSkinKey)
        }
    }

    private func track(_ name: String, _ skin: KeyboardSkin) {
        AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(
            name: name,
            params: ["skin": skin.id, "product": skin.productID ?? "free"]
        ))
    }
}
