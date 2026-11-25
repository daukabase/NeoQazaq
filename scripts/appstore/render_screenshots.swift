// Renders the App Store screenshots (1320×2868, iPhone 6.9") from real simulator captures.
//
// Usage: swift render_screenshots.swift <rawDir> <outDir>
// rawDir holds "<lang>-<capture>.png" for lang in kk/ru/en and capture in:
//   A  home practice field, Classic keyboard, "Сәлем, калайсын" with калайсын | қалайсың in the bar
//   B  same, mixed line "Кешке созвонимся? Мен үйдемін "
//   C1 / C2  same as A with the Түн / Көк style
//   D  privacy onboarding, right after line 2 finished
//   F  welcome chat mid-typing on line 4
// Captures come from the Debug app on an iPhone 6.9" simulator with the QA launch environment
// (ONBOARDING_PAGE, KEYBOARD_SKIN, HOME_PRACTICE; see MainView/AppMain). Every frame shows real UI
// (App Review 2.3.3); the only additions are the headline, the frame and a zoom of the same capture.
//
// Kazakh goes to the English (U.K.) localization (what the Kazakhstan storefront shows), Russian to
// ru, English to en-US.

import SwiftUI
import AppKit

let sky = Color(red: 0, green: 175/255, blue: 202/255)
let gold = Color(red: 254/255, green: 197/255, blue: 12/255)
let navy = Color(red: 11/255, green: 37/255, blue: 69/255)
func hex(_ v: UInt32) -> Color { Color(red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255) }

let canvas = CGSize(width: 440, height: 956)
let screenWidth: CGFloat = 386
let screenHeight = screenWidth * 2868 / 1320
let bezel: CGFloat = 7
let deviceSize = CGSize(width: screenWidth + bezel * 2, height: screenHeight + bezel * 2)
/// Suggestion bar in a capture, in pixels (fixed: the keyboard sits at the bottom of the screen).
let suggestionBarPx = CGRect(x: 0, y: 1852, width: 1320, height: 136)

typealias Copy = [String: (String, String)]   // lang → (headline, subline)

struct Panel {
    let n: Int
    let copy: Copy
    let captures: [String]
    let style: Style
    enum Style { case hero, keyboard, styles, screen, night }
}

let panels: [Panel] = [
    Panel(n: 1, copy: [
        "kk": ("Қалай үйрендің, солай жаз", "Қазақ әріптерін Batyrma өзі қояды"),
        "ru": ("Пиши как привык", "Казахские буквы Batyrma поставит сама"),
        "en": ("Type the way you always do", "Batyrma adds the Kazakh letters for you"),
    ], captures: ["A"], style: .hero),
    Panel(n: 2, copy: [
        "kk": ("Пернетақта ауыстыру жоқ", "Орысша сөздерің өзгермейді"),
        "ru": ("Без смены раскладки", "Русские слова остаются как есть"),
        "en": ("No keyboard switching", "Russian words stay as you typed them"),
    ], captures: ["B"], style: .keyboard),
    Panel(n: 3, copy: [
        "kk": ("Өз стиліңді таңда", "Түн мен Көк — тегін"),
        "ru": ("Выбери свой стиль", "Түн и Көк — бесплатно"),
        "en": ("Pick your style", "Түн and Көк are free"),
    ], captures: ["C1", "C2"], style: .styles),
    Panel(n: 4, copy: [
        "kk": ("Не жазғаныңды көрмейміз", "Мәтінің iPhone-ыңнан шықпайды"),
        "ru": ("Мы не видим, что ты пишешь", "Текст не покидает твой iPhone"),
        "en": ("We never see what you type", "Your text never leaves your iPhone"),
    ], captures: ["D"], style: .screen),
    Panel(n: 5, copy: [
        "kk": ("Таза қазақша — оңай", "Әдетіңді өзгертпей-ақ"),
        "ru": ("Чистый казахский — легко", "Не меняя привычек"),
        "en": ("Clean Kazakh, made easy", "No new habits needed"),
    ], captures: ["F"], style: .night),
]

// MARK: - Pieces

/// Deep midnight with a cool frost glow: premium, quiet, and the dark app UI and white keycap read clearly on it.
struct SkyBackground: View {
    var glow: UnitPoint = UnitPoint(x: 0.12, y: 0)
    var body: some View {
        ZStack {
            LinearGradient(stops: [.init(color: hex(0x131B27), location: 0), .init(color: hex(0x0B111A), location: 0.55), .init(color: hex(0x06090F), location: 1)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [hex(0x7FB2E5).opacity(0.28), .clear], center: glow, startRadius: 0, endRadius: 360)
            RadialGradient(colors: [hex(0xA9C8EA).opacity(0.12), .clear], center: UnitPoint(x: 0.85, y: 0.7), startRadius: 0, endRadius: 320)
        }
    }
}

struct NightBackground: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(colors: [sky.opacity(0.32), .clear], center: .top, startRadius: 0, endRadius: 520)
            RadialGradient(colors: [sky.opacity(0.45), .clear], center: UnitPoint(x: 0.5, y: 0.62), startRadius: 0, endRadius: 300)
            RadialGradient(colors: [gold.opacity(0.10), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 400)
        }
    }
}

struct Device: View {
    let image: NSImage
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .frame(width: screenWidth, height: screenHeight)
            .clipShape(RoundedRectangle(cornerRadius: 56 - bezel, style: .continuous))
            .padding(bezel)
            .background(RoundedRectangle(cornerRadius: 56, style: .continuous).fill(hex(0x1C2230)))
            .overlay(RoundedRectangle(cornerRadius: 56, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1.5))
            .shadow(color: navy.opacity(0.4), radius: 40, y: 24)
    }
}

struct Headline: View {
    let headline: String
    let subline: String
    let ink: Color
    var size: CGFloat = 50
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: headline)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .tracking(-1)
                .foregroundColor(ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: subline)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundColor(ink.opacity(0.75))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: canvas.width - 56, alignment: .leading)
    }
}

/// A full-canvas mask that hides everything above `from` and fades in until `to` (canvas y).
func topFade(from: CGFloat, to: CGFloat) -> some View {
    LinearGradient(stops: [.init(color: .clear, location: from / canvas.height), .init(color: .black, location: to / canvas.height)],
                   startPoint: .top, endPoint: .bottom)
}

/// The icon-style keycap with the transformation, for panel 1.
struct KeycapCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "калайсын")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(navy.opacity(0.35))
                .strikethrough(color: navy.opacity(0.35))
            HStack(alignment: .center, spacing: 8) {
                (Text(verbatim: "қ").foregroundColor(sky) + Text(verbatim: "алайсы").foregroundColor(navy) + Text(verbatim: "ң").foregroundColor(sky))
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Capsule().fill(gold).frame(width: 7, height: 52)
            }
        }
        .padding(.horizontal, 30)
        .frame(width: 384, height: 150, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(navy.opacity(0.08), lineWidth: 6).offset(y: 6).mask(RoundedRectangle(cornerRadius: 34, style: .continuous)))
        )
        .shadow(color: navy.opacity(0.3), radius: 24, y: 14)
    }
}

/// The capture's suggestion bar, zoomed, with a gold ring on the correction (right cell).
struct SuggestionZoom: View {
    let image: NSImage
    let width: CGFloat
    var body: some View {
        let height = width * suggestionBarPx.height / suggestionBarPx.width
        ZStack(alignment: .trailing) {
            Image(nsImage: crop(image, suggestionBarPx)).resizable().frame(width: width, height: height)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(gold, lineWidth: 3)
                .frame(width: width / 2 - 6, height: height - 10)
                .padding(.trailing, 5)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: navy.opacity(0.4), radius: 30, y: 18)
    }
}

func crop(_ image: NSImage, _ rect: CGRect) -> NSImage {
    let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    return NSImage(cgImage: cg.cropping(to: rect)!, size: rect.size)
}

// MARK: - Frame

struct Frame: View {
    let panel: Panel
    let lang: String
    let images: [NSImage]

    var copy: (String, String) { panel.copy[lang]! }
    /// Device placed so its bottom edge sits at y = 940 (keyboard panels).
    var keyboardDeviceCenterY: CGFloat { 940 - deviceSize.height / 2 }
    /// Hero: the device sits a bit lower; the zoom card is centred on its real suggestion bar.
    var heroDeviceCenterY: CGFloat { keyboardDeviceCenterY + 40 }
    var heroSuggestionBarY: CGFloat {
        heroDeviceCenterY - deviceSize.height / 2 + bezel + suggestionBarPx.midY * screenWidth / 1320
    }
    /// Device top at y = 250, running off the bottom (screen panels).
    var bleedDeviceCenterY: CGFloat { 250 + deviceSize.height / 2 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch panel.style {
            case .hero:
                SkyBackground()
                Device(image: images[0])
                    .position(x: canvas.width / 2, y: heroDeviceCenterY)
                    .mask(topFade(from: 380, to: 470))
                KeycapCard().position(x: canvas.width / 2, y: 60 + 75)
                Headline(headline: copy.0, subline: copy.1, ink: .white, size: 34)
                    .position(x: canvas.width / 2, y: 60 + 150 + 22 + 50)
                SuggestionZoom(image: images[0], width: 408)
                    .position(x: canvas.width / 2 + 6, y: heroSuggestionBarY)
            case .keyboard:
                SkyBackground()
                Device(image: images[0])
                    .position(x: canvas.width / 2, y: keyboardDeviceCenterY)
                    .mask(topFade(from: 250, to: 320))
                header(ink: .white)
            case .styles:
                SkyBackground()
                ZStack {
                    Device(image: images[0]).scaleEffect(0.86).rotationEffect(.degrees(6)).offset(x: 78, y: -24)
                    Device(image: images[1]).scaleEffect(0.86).rotationEffect(.degrees(-3)).offset(x: -34, y: 10)
                }
                .position(x: canvas.width / 2, y: keyboardDeviceCenterY + 40)
                .mask(topFade(from: 280, to: 360))
                header(ink: .white)
            case .screen:
                SkyBackground()
                Device(image: images[0]).position(x: canvas.width / 2, y: bleedDeviceCenterY)
                header(ink: .white)
            case .night:
                NightBackground()
                Device(image: images[0]).position(x: canvas.width / 2, y: bleedDeviceCenterY)
                header(ink: .white)
            }
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }

    func header(ink: Color) -> some View {
        Headline(headline: copy.0, subline: copy.1, ink: ink)
            .padding(.leading, 28)
            .padding(.top, 64)
            .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
    }
}

// MARK: - Main

let args = CommandLine.arguments
let rawDir = args[1], outDir = args[2]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

@MainActor func run() {
    for lang in ["kk", "ru", "en"] {
        for panel in panels {
            let images = panel.captures.compactMap { NSImage(contentsOfFile: "\(rawDir)/\(lang)-\($0).png") }
            guard images.count == panel.captures.count else { print("skip \(lang)-\(panel.n): missing capture"); continue }
            let renderer = ImageRenderer(content: Frame(panel: panel, lang: lang, images: images))
            renderer.scale = 3
            guard let cg = renderer.cgImage else { print("fail \(lang)-\(panel.n)"); continue }
            // Opaque RGB, no alpha (App Store requirement).
            let ctx = CGContext(data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            let out = "\(outDir)/\(lang)-\(panel.n).png"
            try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
            print("wrote", out, cg.width, "x", cg.height)
        }
    }
}
MainActor.assumeIsolated { run() }
