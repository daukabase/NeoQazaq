//
//  SkinPickerView.swift
//  Qazaqsha
//
//  A horizontal row of mini keyboards, one per skin. Tap to apply; locked skins show their
//  price (tap to buy), "Soon" until the product exists, or the month a limited edition is sold.
//

import SwiftUI
import QazaqFoundation

struct SkinPickerView: View {
    @ObservedObject var store: SkinStore = .shared
    var showsRestore = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(KeyboardSkin.all) { skin in
                        Button {
                            // The keyboard picks up a new style when it next appears, so close it:
                            // tapping the field again shows the chosen style right away.
                            if store.isUnlocked(skin) {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            Task { await store.tapped(skin) }
                        } label: {
                            SkinTile(
                                skin: skin,
                                isSelected: store.selectedID == skin.id,
                                badge: badge(for: skin),
                                isBusy: store.purchasingProductID != nil && store.purchasingProductID == skin.productID
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!store.isUnlocked(skin) && store.price(for: skin) == nil)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }

            if showsRestore {
                Button("skins_restore") { Task { await store.restore() } }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 24)
            }
        }
        .task { await store.loadIfNeeded() }
    }

    private func badge(for skin: KeyboardSkin) -> SkinTile.Badge {
        if store.isUnlocked(skin) { return .none }
        if case .limited = skin.availability, !skin.isOnSale() { return .text(String(localized: "skins_only_in_march")) }
        if let price = store.price(for: skin) { return .price(price) }
        return .text(String(localized: "skins_soon"))
    }
}

struct SkinTile: View {
    enum Badge: Equatable {
        case none
        case price(String)
        case text(String)
    }

    let skin: KeyboardSkin
    let isSelected: Bool
    let badge: Badge
    var isBusy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MiniKeyboard(skin: skin)
                .frame(width: 112, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? OnboardingTheme.accent : Color.white.opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white, OnboardingTheme.accent)
                            .font(.system(size: 18))
                            .padding(5)
                    } else if badge != .none {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                            .padding(5)
                    }
                }
                .overlay {
                    if isBusy { ProgressView().tint(.white) }
                }

            HStack(spacing: 4) {
                Text(verbatim: skin.name)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                switch badge {
                case .none:
                    EmptyView()
                case .price(let price):
                    Text(verbatim: price)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(OnboardingTheme.gold)
                case .text(let text):
                    Text(verbatim: text)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .lineLimit(1)
            .frame(width: 112, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Three rows of keys and a bottom row (system key, space, return) in the skin's colours.
struct MiniKeyboard: View {
    let skin: KeyboardSkin

    var body: some View {
        let background = skin.background ?? [Color(hex: 0xD1D4DA)]
        VStack(spacing: 4) {
            row(count: 10)
            row(count: 9).padding(.horizontal, 5)
            row(count: 7).padding(.horizontal, 14)
            HStack(spacing: 3) {
                key(skin.systemKey).frame(width: 18)
                key(skin.key)
                key(skin.primary).frame(width: 22)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: background, startPoint: .top, endPoint: .bottom))
    }

    private func row(count: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { _ in key(skin.key) }
        }
    }

    private func key(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 0.5)
    }
}

struct SkinPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackground()
            SkinPickerView()
        }
        .preferredColorScheme(.dark)
    }
}
