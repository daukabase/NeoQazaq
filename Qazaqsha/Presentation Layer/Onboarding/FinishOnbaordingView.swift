//
//  FinishOnbaordingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 04.11.2024.
//

import SwiftUI
struct FinishOnboardingView: View {
    struct AppLink: Identifiable {
        let id = UUID()
        let icon: Image
        let name: String
        let url: URL
    }
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let links: [AppLink] = [
        .init(
            icon: Asset.Images.whatsapp.swiftUIImage,
            name: "WhatsApp",
            url: URL(string: "whatsapp://send?text=Сәлем")!
        ),
        .init(
            icon: Asset.Images.telegram.swiftUIImage,
            name: "Telegram",
            url: URL(string: "tg://msg?text=Сәлем")!
        ),
        .init(
            icon: Asset.Images.instagram.swiftUIImage,
            name: "Instagram",
            url: URL(string: "instagram://message?text=Сәлем")!
        ),
        .init(
            icon: Asset.Images.tiktok.swiftUIImage,
            name: "TikTok",
            url: URL(string: "snssdk1233://message/chat")!
        )
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            Text("👋")
                .font(.system(size: 80))
                .padding(.top, 40)
            
            // Main Title
            VStack(spacing: 8) {
                Text("Say Сәлем!")
                    .font(.system(size: 32, weight: .bold))
                Text("Tap an app to start typing")
                    .font(.body)
                    .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
            }
            
            // Apps Section
            VStack(spacing: 16) {
                Text("Start typing in your favorite apps")
                    .font(.headline)
                
                // App Icons
                HStack(spacing: 24) {
                    // WhatsApp
                    ForEach(links) { link in
                        appLink(
                            icon: link.icon,
                            name: link.name,
                            url: link.url
                        )
                    }
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.backgroundSecondary)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Start Button
            Button(action: {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                dismiss()
            }) {
                Text("Start Using NeoQazaq")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Asset.Colors.lightAction.swiftUIColor)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
    
    @ViewBuilder
    private func appLink(
        icon: Image,
        name: String,
        url: URL,
        size: CGSize = .init(width: 48, height: 48)
    ) -> some View {
        Link(destination: url) {
            VStack(spacing: 8) {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(Asset.Colors.text.swiftUIColor)
            }
        }
    }
}

struct FinishOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        FinishOnboardingView()
        FinishOnboardingView().preferredColorScheme(.dark)
    }
}
