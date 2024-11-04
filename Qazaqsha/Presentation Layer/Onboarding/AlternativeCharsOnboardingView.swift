//
//  AlternativeCharsOnboardingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 05.10.2024.
//

import SwiftUI
import QazaqFoundation

struct AlternativeCharsOnboardingView: View {
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    static let iconSize = CGFloat(100)
    private let playViewNames = ["longPressADark", "longPressShortGifDark", "longPressIDark", "longPressODark"]
    private let adaptiveColumn = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        Form {
            Section(content: {
                VStack(alignment: .center, spacing: 0) {
                    appIcon
                    bulletPoints
                        .padding(.trailing, 16)
                    exampleView
                }.frame(maxWidth: .infinity)
            }, header: {
                headerView
            })
            .listRowInsets(EdgeInsets())
        }
        .modifier(FormHiddenBackground())
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 8, content: {
            Text("Qazaq letters selection")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .lineLimit(2)
        })
        .textCase(nil)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 32)
    }
    
    var appIcon: some View {
        Asset.Images.appIconNoBackground.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Self.iconSize, height: Self.iconSize)
            .background(
                RoundedRectangle(cornerRadius: 25.0)
                    .frame(width: Self.iconSize / 2, height: Self.iconSize / 2)
                    .foregroundStyle(.white)
                    .shadow(color: .blue, radius: 15, x: -8, y: 8)
            )
    }

//    var bulletPoints: some View {
//        VStack(alignment: .leading, spacing: 5) {
//            bulletPoint("Long press that available letter")
//            Text("Letters that available for long press: А -> Ә, Ғ, Қ, Ң, Ө, Ұ, Ү, Һ, І")
//                .font(.caption)
//                .foregroundStyle(.lightSecondary)
//            bulletPoint("Slide to select specific letter")
//            bulletPoint("Release")
//        }
//        .foregroundColor(Asset.Colors.text.swiftUIColor)
//        .font(.body)
//        .textCase(nil) // Ensuring text case is not altered
//        .padding([.bottom, .horizontal], 16)
//    }
    var bulletPoints: some View {
        VStack(alignment: .leading, spacing: 5) {
            bulletPoint("Long press available letter")
            // Available letters mapping in grid
            VStack(alignment: .leading, spacing: 4) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    alignment: .leading,
                    spacing: 8
                ) {
                    letterMapping("А", "Ә")
                    letterMapping("У", "Ұ, Ү")
                    letterMapping("И", "І")
                    letterMapping("Ы", "І")
                    letterMapping("К", "Қ")
                    letterMapping("Н", "Ң")
                    letterMapping("Г", "Ғ")
                    letterMapping("Х", "Һ")
                }
            }
            .padding(.leading, 20)
            .padding(.vertical, 8)
            
            bulletPoint("Slide to select specific letter")
            bulletPoint("Release")
        }
        .foregroundColor(Asset.Colors.text.swiftUIColor)
        .font(.body)
        .textCase(nil)
        .padding([.bottom, .horizontal], 16)
    }

    private func letterMapping(_ from: String, _ to: String) -> some View {
        HStack(spacing: 4) {
            Text(from)
                .frame(maxWidth: .infinity)
                .fontWeight(.medium)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
            Text("→")
                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
            Text(to)
                .frame(maxWidth: .infinity)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Asset.Colors.text.swiftUIColor.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Asset.Colors.text.swiftUIColor.opacity(0.1), lineWidth: 1)
        )
    }

    func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text("•")
                .foregroundColor(Asset.Colors.text.swiftUIColor)
            Text(text)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)  // Ensures text wraps correctly
        }
    }

    var exampleView: some View {
        VStack(alignment: .center) {
            Text("Example")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            LazyVGrid(columns: adaptiveColumn, spacing: 20) {
                let availableWidth = UIScreen.main.bounds.width - 48
                let itemWidth = availableWidth / 2
                ForEach(playViewNames, id: \.self) { fileName in
                    videoView(with: fileName)
                        .frame(width: itemWidth, height: itemWidth / 1.3)
                }
            }
        }
        .background(Asset.Colors.keyboardBackground.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding([.top, .horizontal], 16)
    }

    func videoView(with videoName: String) -> some View {
        LoopingVideoPlayer(videoName: videoName, fileExtension: "mov")
            .padding(16)
    }

    var gifLongPressExample: some View {
        let ratio = 1.16078431
        let width = UIScreen.main.bounds.width - 32 - 16
        let height = width / ratio

        let gifName = colorScheme == .dark ? "longPressDark" : "longPressWhite"

        return GifImage(name: gifName)
            .frame(width: width, height: height)
    }
}

struct AlternativeCharsOnboardingView_Preview: PreviewProvider {
    static var previews: some View {
        AlternativeCharsOnboardingView()
        AlternativeCharsOnboardingView().preferredColorScheme(.dark)
    }
}

import SwiftUI
import AVKit

struct LoopingVideoPlayer: View {
    private let player: AVQueuePlayer
    private let playerLooper: AVPlayerLooper
    
    init?(videoName: String, fileExtension: String) {
        // Create player item
        guard let fileUrl = Bundle.main.url(forResource: videoName, withExtension: fileExtension) else {
            assertionFailure("Failed to find video file: \(videoName).\(fileExtension)")
            return nil
        }

        // Create player and looper
        let player = AVQueuePlayer()
        let playerItem = AVPlayerItem(url: fileUrl)
        self.player = player
        self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        // Mute the video
        player.isMuted = true
    }
    
    var body: some View {
        // Calculate dimensions based on screen size
        VideoPlayer(player: player)
            .disabled(true)  // Disable player controls
            .onAppear {
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}
