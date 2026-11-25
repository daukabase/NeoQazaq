//
//  OnboardingChat.swift
//  Qazaqsha
//
//  Building blocks for the conversational onboarding (inspired by Opal): a dark screen,
//  a glowing Batyrma "orb", and Batyrma talking in short lines. Each line is typed the way
//  people really type (without ә, қ, ң…) and every word is corrected the moment it's
//  finished, so the onboarding itself demonstrates the keyboard.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - Theme

enum OnboardingTheme {
    /// Sky blue of the Kazakh flag.
    static let accent = Color(red: 0, green: 175 / 255, blue: 202 / 255)
    /// Sun gold of the Kazakh flag.
    static let gold = Color(red: 254 / 255, green: 197 / 255, blue: 12 / 255)
    static let dimmedLineOpacity = 0.4
}

/// Black with a soft blue glow at the top and a hint of gold, like a night sky over the steppe.
struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [OnboardingTheme.accent.opacity(0.32), .clear],
                center: .top, startRadius: 0, endRadius: 420
            )
            RadialGradient(
                colors: [OnboardingTheme.gold.opacity(0.08), .clear],
                center: .bottomTrailing, startRadius: 0, endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

/// The app icon floating in a slowly breathing glow: Batyrma's "face" during onboarding.
struct BatyrmaOrb: View {
    var size: CGFloat = 84
    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(OnboardingTheme.accent.opacity(0.45))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.4)
                .scaleEffect(breathing ? 1.1 : 0.9)
            Asset.Images.appIconNoBackground.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 1.5, height: size * 1.5)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.375, style: .continuous)
                        .fill(.white)
                        .frame(width: size * 0.75, height: size * 0.75)
                )
        }
        .frame(width: size * 1.5, height: size * 1.5)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { breathing = true }
        }
    }
}

/// White pill, black label, the single main action of a screen.
struct OnboardingPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(.white))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Thin progress bar at the top.
struct OnboardingProgressBar: View {
    let count: Int
    let current: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule().fill(Color.white)
                    .frame(width: proxy.size.width * CGFloat(current + 1) / CGFloat(max(count, 1)))
            }
        }
        .frame(height: 4)
        .animation(.easeInOut, value: current)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "\(current + 1) / \(count)"))
    }
}

// MARK: - Shala → taza

/// How people type Kazakh without Kazakh letters, and how to highlight the letters Batyrma restores.
enum Shala {
    private static let foldMap: [Character: Character] = [
        "ә": "а", "Ә": "А", "ғ": "г", "Ғ": "Г", "қ": "к", "Қ": "К", "ң": "н", "Ң": "Н",
        "ө": "о", "Ө": "О", "ұ": "у", "Ұ": "У", "ү": "у", "Ү": "У", "һ": "х", "Һ": "Х",
        "і": "и", "І": "И",
    ]

    /// "қалайсың" → "калайсын": the text as typed on a Russian layout.
    static func fold(_ text: String) -> String {
        String(text.map { foldMap[$0] ?? $0 })
    }

    static func isRestored(_ character: Character) -> Bool {
        foldMap[character] != nil
    }

    /// The text with restored Kazakh letters in the accent color.
    static func highlighted(_ text: String, base: Color = .white) -> Text {
        text.reduce(Text(verbatim: "")) { result, character in
            result + Text(verbatim: String(character))
                .foregroundColor(isRestored(character) ? OnboardingTheme.accent : base)
        }
    }
}

private enum Haptics {
    private static let generator = UIImpactFeedbackGenerator(style: .soft)

    static func correction() {
        generator.impactOccurred(intensity: 0.6)
    }
}

// MARK: - Typed lines

/// Batyrma "speaks": lines are typed one after another, earlier lines fade back. Each word
/// is typed without Kazakh letters and swapped for the correct word when it's finished.
/// Appending to `lines` continues the conversation; tapping skips the animation.
/// `onFinished` is called whenever all current lines are shown.
struct TypedLinesView: View {
    let lines: [String]
    /// Shows "Tap to skip" under the text while typing (for long intros).
    var showsSkipHint = false
    /// Fade earlier lines (conversation feel). Off where every line matters (privacy).
    var dimsEarlierLines = true
    var onFinished: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Lines already fully shown.
    @State private var shown: [String] = []
    /// The line being typed: corrected words so far and the word being typed.
    @State private var typedPart = ""
    @State private var currentWord = ""
    /// The rest of the line, laid out but invisible, so a word that won't fit starts on the next row
    /// from its first letter instead of jumping there halfway through.
    @State private var upcoming = ""
    @State private var isTyping = false
    @State private var skipAnimation = false

    private static let fontSize: CGFloat = 24
    private static let cursor = "▍"

    /// Width of the cursor glyph. Negative kerning by this much gives the cursor zero layout width,
    /// so it never pushes a word to the next row (the finished line has no cursor).
    private static let cursorAdvance: CGFloat = {
        var font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        if let rounded = font.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: rounded, size: fontSize)
        }
        return (cursor as NSString).size(withAttributes: [.font: font]).width
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(shown.enumerated()), id: \.offset) { index, line in
                // The latest line keeps its restored letters highlighted until the next line starts
                // typing; then it turns one calm color, which is easier to read.
                let isLatest = index == shown.count - 1 && !isTyping
                (isLatest ? Shala.highlighted(line) : Text(verbatim: line).foregroundColor(.white))
                    .opacity(!dimsEarlierLines || isLatest ? 1 : OnboardingTheme.dimmedLineOpacity)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if isTyping {
                (Shala.highlighted(typedPart)
                    + Text(verbatim: currentWord).foregroundColor(.white)
                    + Text(verbatim: Self.cursor).foregroundColor(OnboardingTheme.accent).kerning(-Self.cursorAdvance)
                    + Text(verbatim: upcoming).foregroundColor(.clear))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if showsSkipHint && isTyping && !skipAnimation {
                Text("tap_to_skip")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.35))
                    .transition(.opacity)
            }
        }
        .font(.system(size: Self.fontSize, weight: .semibold, design: .rounded))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { skipAnimation = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: lines.joined(separator: "\n")))
        .task(id: lines) { await typeRemainingLines() }
    }

    private func typeRemainingLines() async {
        // A new line arrived while one was being typed: finish that one at once.
        if isTyping, shown.count < lines.count {
            finishCurrentLine(lines[shown.count])
        }
        while shown.count < lines.count {
            let line = lines[shown.count]
            if reduceMotion || skipAnimation {
                withAnimation { shown.append(line) }
                continue
            }
            typedPart = ""
            currentWord = ""
            upcoming = line   // reserves the line's full height from the start
            // The previous line loses its highlight and fades back gently while the new one begins.
            withAnimation(.easeInOut(duration: 0.3)) { isTyping = true }
            guard await pause(0.2) else { return }

            let words = line.components(separatedBy: " ")
            for (index, word) in words.enumerated() {
                let typed = Shala.fold(word)
                let rest = words[(index + 1)...].joined(separator: " ")
                let afterWord = rest.isEmpty ? "" : " " + rest
                var untyped = Substring(typed)
                upcoming = typed + afterWord
                for character in typed where !skipAnimation {
                    currentWord.append(character)
                    untyped = untyped.dropFirst()
                    upcoming = String(untyped) + afterWord
                    // Small jitter feels human; a wide one looks like stutter at this pace.
                    guard await pause(Double.random(in: 0.025...0.035)) else { return }
                }
                if skipAnimation { break }
                if typed != word {
                    // A beat so the eye catches the swap, with a light tap.
                    guard await pause(0.12) else { return }
                    Haptics.correction()
                }
                withAnimation(.easeOut(duration: 0.15)) {
                    typedPart += word + (index < words.count - 1 ? " " : "")
                    currentWord = ""
                    upcoming = rest
                }
            }
            finishCurrentLine(line)
            if !skipAnimation {
                // A full second to read the finished sentence before the next one starts.
                guard await pause(Self.pauseAfterLine / Self.pace) else { return }
            }
        }
        onFinished()
    }

    private func finishCurrentLine(_ line: String) {
        shown.append(line)
        isTyping = false
        typedPart = ""
        currentWord = ""
        upcoming = ""
    }

    /// Scales every typing delay. 1 / 0.75 = 25% slower than the original pace:
    /// ~25 characters/s while typing, comfortable to read along at this font size.
    private static let pace = 1 / 0.75
    /// Real seconds between sentences (not scaled by `pace`).
    private static let pauseAfterLine: Double = 1.0

    /// Sleeps for `seconds × pace`; false if the task was cancelled.
    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(nanoseconds: UInt64(seconds * Self.pace * 1_000_000_000))) != nil
    }
}

// MARK: - Setup video

/// A screen recording of the real setup (Settings → Keyboards → Batyrma), looping silently
/// in a phone-like frame.
struct SetupVideoView: View {
    private static let aspectRatio: CGFloat = 444 / 600

    var body: some View {
        LoopingVideo(assetName: "setup_video")
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: "Settings → Keyboards → Batyrma"))
    }
}

private struct LoopingVideo: UIViewRepresentable {
    let assetName: String

    func makeUIView(context: Context) -> LoopingPlayerView {
        LoopingPlayerView(url: Self.fileURL(for: assetName))
    }

    func updateUIView(_ uiView: LoopingPlayerView, context: Context) {}

    /// AVPlayer needs a file: copy the asset-catalog data to Caches once.
    private static func fileURL(for name: String) -> URL? {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(name).mp4")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        guard let data = NSDataAsset(name: name)?.data else { return nil }
        return (try? data.write(to: url)) != nil ? url : nil
    }
}

final class LoopingPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var observer: NSObjectProtocol?

    init(url: URL?) {
        super.init(frame: .zero)
        guard let url else { return }
        // The clip has no audio track, so it never interrupts the user's music.
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        let playerLayer = layer as! AVPlayerLayer
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        player.play()
        // Playback pauses while the user is in Settings; resume on return.
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.player.play() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }
}
