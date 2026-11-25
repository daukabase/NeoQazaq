//
//  FinishOnbaordingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 04.11.2024.
//
//  Done: the user picks a keyboard skin (free ones apply at once; paid ones show their price),
//  then Batyrma sends them off to write their first message in a messenger.
//

import SwiftUI

struct FinishOnboardingView: View {
    struct AppLink: Identifiable {
        let id = UUID()
        let icon: Image
        let name: String
        let url: URL
    }

    static let lines = [
        "Дайынсың! 🎉",
        "Пернетақтаңның түсін таңда 🎨",
        "Сосын достарыңа қазақша сәлем жаз 👋",
    ]

    let links: [AppLink] = [
        .init(
            icon: Asset.Images.whatsapp.swiftUIImage,
            name: "WhatsApp",
            url: URL(string: "whatsapp://send?text=Салем")!
        ),
        .init(
            icon: Asset.Images.telegram.swiftUIImage,
            name: "Telegram",
            url: URL(string: "tg://msg?text=Салем")!
        ),
        .init(
            icon: Asset.Images.instagram.swiftUIImage,
            name: "Instagram",
            url: URL(string: "instagram://message?text=Салем")!
        ),
        .init(
            icon: Asset.Images.tiktok.swiftUIImage,
            name: "TikTok",
            url: URL(string: "snssdk1233://message/chat")!
        )
    ]

    var onReady: () -> Void = {}

    @State private var showsApps = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                TypedLinesView(lines: Self.lines) {
                    withAnimation(.easeOut) { showsApps = true }
                    onReady()
                }

                if showsApps {
                    SkinPickerView(showsRestore: false)
                        .padding(.horizontal, -24)
                        .transition(.opacity)

                    HStack(spacing: 0) {
                        ForEach(links) { link in
                            appLink(link)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 20)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.08)))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
    }

    private func appLink(_ link: AppLink) -> some View {
        Link(destination: link.url) {
            VStack(spacing: 8) {
                link.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(link.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct FinishOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackground()
            FinishOnboardingView()
        }
        .preferredColorScheme(.dark)
    }
}
