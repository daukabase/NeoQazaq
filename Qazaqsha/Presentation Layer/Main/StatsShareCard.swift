//
//  StatsShareCard.swift
//  Qazaqsha
//
//  A story-sized card (1080×1920) with the user's stats, for Instagram/TikTok stories, WhatsApp
//  and Telegram. Shared through the system share sheet: Instagram Stories, TikTok and WhatsApp
//  all appear there, and their own direct-share APIs need app IDs or SDKs we don't have.
//
//  The card is rendered with ImageRenderer from the same SwiftUI view the preview shows.
//

import SwiftUI
import UIKit
import QazaqFoundation

/// What the card shows: this month's restored letters, or the all-time total early in a month.
struct StatsShareContent {
    let letters: Int
    let isThisMonth: Bool
    let totalWords: Int

    init(letters: Int, isThisMonth: Bool, totalWords: Int) {
        self.letters = letters
        self.isThisMonth = isThisMonth
        self.totalWords = totalWords
    }

    init(stats: TypingStats.Snapshot) {
        let isThisMonth = stats.monthLetters > 0
        self.init(
            letters: isThisMonth ? stats.monthLetters : stats.totalLetters,
            isThisMonth: isThisMonth,
            totalWords: stats.totalWords
        )
    }

    var shareText: String {
        isThisMonth
            ? String(localized: "home_stats_share_text\(letters)")
            : String(localized: "share_card_share_text_total\(letters)")
    }
}

/// The card itself, laid out in points for a 360×640 canvas (×3 = 1080×1920).
struct StatsShareCardView: View {
    static let size = CGSize(width: 360, height: 640)

    let content: StatsShareContent

    var body: some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: 0) {
                brand
                Spacer(minLength: 0)
                hero
                Spacer(minLength: 0)
                footer
            }
            // Stories put the profile row on top and the reply bar at the bottom: keep clear of both.
            .padding(.horizontal, 32)
            .padding(.top, 84)
            .padding(.bottom, 76)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .environment(\.colorScheme, .dark)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.07, blue: 0.13), .black],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [OnboardingTheme.accent.opacity(0.45), .clear],
                center: UnitPoint(x: 0.2, y: 0.05), startRadius: 0, endRadius: 380
            )
            RadialGradient(
                colors: [OnboardingTheme.gold.opacity(0.18), .clear],
                center: UnitPoint(x: 1, y: 0.95), startRadius: 0, endRadius: 320
            )
        }
    }

    private var brand: some View {
        HStack(spacing: 12) {
            Asset.Images.appIconWelcome.swiftUIImage
                .resizable()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(verbatim: "Batyrma")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(verbatim: content.letters.formatted())
                .font(.system(size: 104, weight: .heavy, design: .rounded))
                .foregroundColor(OnboardingTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(content.isThisMonth ? "share_card_letters_month" : "share_card_letters_total")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            example
                .padding(.top, 6)
            Text("home_stats_words\(content.totalWords)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    /// What Batyrma does, in one glance: the word as typed → the word as fixed.
    private var example: some View {
        HStack(spacing: 10) {
            Text(verbatim: Shala.fold("қалайсың"))
                .foregroundColor(.white.opacity(0.45))
                .strikethrough(color: .white.opacity(0.3))
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(OnboardingTheme.gold)
            Shala.highlighted("қалайсың")
        }
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("share_card_tagline")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text("share_card_find")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(OnboardingTheme.gold)
        }
    }

    /// The card as a 1080×1920 image.
    @MainActor
    static func render(_ content: StatsShareContent) -> UIImage? {
        let renderer = ImageRenderer(content: StatsShareCardView(content: content))
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// Preview of the card with one big Share button. Opened from the home stats card.
struct StatsShareSheet: View {
    let content: StatsShareContent

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            OnboardingBackground()
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                GeometryReader { proxy in
                    let scale = min(proxy.size.width / StatsShareCardView.size.width,
                                    proxy.size.height / StatsShareCardView.size.height)
                    StatsShareCardView(content: content)
                        .scaleEffect(scale)
                        .frame(width: StatsShareCardView.size.width * scale,
                               height: StatsShareCardView.size.height * scale)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: OnboardingTheme.accent.opacity(0.35), radius: 30)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .accessibilityElement()
                .accessibilityLabel(Text(verbatim: content.shareText))

                VStack(spacing: 12) {
                    Button(action: share) {
                        Label("share_card_button", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(OnboardingPillButtonStyle())
                    destinations
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(name: "home_stats_card_opened"))
        }
    }

    /// Where the card goes: a hint of the apps in the share sheet.
    private var destinations: some View {
        HStack(spacing: 10) {
            ForEach([Asset.Images.instagram, Asset.Images.tiktok, Asset.Images.whatsapp, Asset.Images.telegram], id: \.name) { asset in
                asset.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            Text("share_card_destinations")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.55))
        }
        .accessibilityElement(children: .combine)
    }

    @MainActor
    private func share() {
        guard let image = StatsShareCardView.render(content) else { return }
        var items: [Any] = [image, content.shareText]
        if let url = GlobalConstants.appStoreURL { items.append(url) }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { activity, completed, _, _ in
            guard completed else { return }
            // Which app people share to (e.g. Instagram's extension id) tells us what works.
            AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(
                name: "home_stats_shared",
                params: ["destination": activity?.rawValue ?? "unknown"]
            ))
        }
        guard let top = UIApplication.shared.topViewController else { return }
        controller.popoverPresentationController?.sourceView = top.view
        top.present(controller, animated: true)
    }
}

extension UIApplication {
    /// The view controller currently on top, to present UIKit sheets from SwiftUI.
    var topViewController: UIViewController? {
        var top = connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

struct StatsShareCardView_Previews: PreviewProvider {
    static var previews: some View {
        StatsShareCardView(content: StatsShareContent(letters: 1240, isThisMonth: true, totalWords: 3900))
            .previewLayout(.sizeThatFits)
    }
}
