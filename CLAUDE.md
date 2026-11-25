# Batyrma (NeoQazaq)

The product, architecture and decisions are in `CONTEXT.md`; read it first. Strategy notes are in `PRODUCT_STRATEGY.md`.

## Working rules
- **Commit each finished piece of work.** After each piece of work is done and builds, make a small, focused commit with a clear message. Don't let unrelated changes pile up uncommitted. Push when the founder asks.
- Never commit secrets: `Config/Secrets.xcconfig` is gitignored and must stay that way.
- Build check: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Qazaqsha.xcodeproj -scheme Qazaqsha -destination 'generic/platform=iOS Simulator' build`.
- User-facing copy is in `Resources/Localizable.xcstrings` (en / kk / ru). Keep Kazakh natural, not a calque of Russian. Never use "advertising / реклама / жарнама" wording: sponsors are framed as support for the Kazakh language.
- App Store assets live in `AppStore/<version>/` (metadata, screenshots per localization); screenshots are rendered by `scripts/appstore/render_screenshots.swift`.
