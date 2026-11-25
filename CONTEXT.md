# Batyrma — Working Context

Last updated: 2026-11-09

## 1. In-app feedback → Telegram (done)

**Problem:** Feedback used to open the Mail composer with a pre-filled template. Users tapped Send without typing anything, so lots of empty emails came in.

**Solution:** An in-app SwiftUI form that posts to a Telegram bot.

- **Options on the main screen** (`MainView.swift`, `actionsSection`):
  - 💬 Tech support (`FeedbackType.question`). Covers both questions and bugs; the separate "Report a bug" option was removed.
  - 🤝 Collaboration (`FeedbackType.collaboration`). The contact field is **required**.
- **Form** (`FeedbackView` in `Qazaqsha/Presentation Layer/Main/FeedbackService.swift`):
  - Send is disabled until the message has at least 10 non-whitespace characters.
  - Optional "Email or Telegram" contact field (required for Collaboration).
  - The sheet can't be swiped away while it has text.
  - 30 s cooldown between sends per device (stored in UserDefaults key `feedbackLastSentAt`).
  - Messages are capped at 3000 chars (Telegram's limit is 4096).
- **Telegram message format:** a header with a hashtag for filtering (`💬 Support request #support`, `🤝 Collaboration request #collab`), then the message, contact, device model (e.g. `iPhone15,2`), iOS version, app version, language, and whether the keyboard is enabled.
- **Localization:** new `feedback_*` keys in `Resources/Localizable.xcstrings` (en/kk/ru). The old email-template keys, `Report a bug` and `feedback_bug_prompt` were removed.
- `MessageUI` and `MFMailComposeViewController` are no longer used.

### Bot & where data lives
- Bot: **@batyrmaapp** (created via @BotFather).
- Messages go to the developer's private chat with the bot (chat ID `251317695`, account `daukabase`). No channel is used.
- The bot has no backend. It only receives what the app posts; if someone messages it directly, nothing happens.
- **Storage:** messages exist only in that Telegram chat, kept until deleted. Nothing goes to Firebase, Amplitude, or any other server. The app stores only the last-send timestamp on the device.
- Caveat: the bot token ships inside the app binary. If it gets abused, revoke it in @BotFather and release an update with a new token.

### Secrets / config
- `Config/Qazaqsha.xcconfig` (committed): the base config for the Qazaqsha target (Debug and Release). It uses `#include? "Secrets.xcconfig"`.
- `Config/Secrets.xcconfig` (**git-ignored**): holds `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.
- `Config/Secrets.example.xcconfig` (committed): template. On a new machine, copy it to `Secrets.xcconfig` and fill it in.
- `Qazaqsha/Info.plist` keys `TelegramBotToken` and `TelegramChatID` get their values from those build settings. If they're unset, the form shows "Couldn't send".

### Release TODOs for feedback
- [ ] Test on a real device: send from Tech support and Collaboration, and confirm the messages arrive in Telegram.
- [ ] Update the Privacy Policy (termsfeed page): feedback, including contact info, is sent to Telegram.
- [ ] App Store Connect → App Privacy: declare Contact Info → Email Address and User Content → Customer Support (not used for tracking).

## 2. Build fix: Crashlytics dependency cycle (done)

Archiving failed with "Cycle inside Qazaqsha". The "Upload dSYM into Crashlytics" build phase ran before "Embed Frameworks". It was moved to the **last** build phase of the Qazaqsha target in `project.pbxproj`. It only runs during archive (`runOnlyForDeploymentPostprocessing = 1`).

## 3. App Store build (blocked)

- An archive and export with Xcode 16.4 both worked. Signing: automatic, team `JNA8QM22SG`, Cloud Managed Apple Distribution certificate.
- **The upload was rejected:** "built with the iOS 18.5 SDK … must be built with the iOS 26 SDK or later (Xcode 26+)".
- Mac: macOS 15.6.1, which is new enough for Xcode 26. Only Xcode 16.4 is installed (`/Applications/Xcode.app`).

### Next steps
1. Install Xcode 26.x from developer.apple.com/download/all and save it as `/Applications/Xcode-26.app` (keep 16.4 as a fallback).
2. `sudo xcode-select -s /Applications/Xcode-26.app`
3. Build and fix any compiler or package issues (KeyboardKit, Firebase and Amplitude may need updates).
4. **Fix the build number:** `Qazaqsha/Info.plist` hard-codes `CFBundleVersion = 1`. Change it to `$(CURRENT_PROJECT_VERSION)` and bump it per upload. The marketing version is currently 1.1.3.
5. Archive and export again, and confirm the build uses the iOS 26 SDK.
6. Note: the iOS 26 SDK automatically applies the "Liquid Glass" UI. To keep the old look temporarily, add `UIDesignRequiresCompatibility = YES` to `Info.plist`.

### Archive / export commands
```sh
xcodebuild -project Qazaqsha.xcodeproj -scheme "Qazaqsha - Release" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Qazaqsha.xcarchive \
  -allowProvisioningUpdates archive

xcodebuild -exportArchive -archivePath build/Qazaqsha.xcarchive -exportPath build/Export \
  -exportOptionsPlist Config/ExportOptions.plist -allowProvisioningUpdates
```
`Config/ExportOptions.plist`: `method = app-store-connect`, `destination = export`, `signingStyle = automatic`, `teamID = JNA8QM22SG`, `uploadSymbols = true`.

## Files touched
- `Qazaqsha/Presentation Layer/Main/FeedbackService.swift`: rewritten (Telegram service and form)
- `Qazaqsha/Presentation Layer/Main/MainView.swift`: feedback sheet and buttons
- `Qazaqsha/Info.plist`: Telegram keys
- `Resources/Localizable.xcstrings`: feedback strings
- `Qazaqsha.xcodeproj/project.pbxproj`: Crashlytics phase order, `Config` group, base xcconfig
- `Config/*` (xcconfigs and `ExportOptions.plist`), `.gitignore`

Nothing has been committed yet.

## 4. Release 1.2.0 fixes (in progress, 2026-11-23)

Spec: `specs/01-fix-spec.md` (see the status table in §0.2a). Design for the next engine: `specs/02-bilingual-prediction-design.md`.

- **Xcode:** Xcode 27.2 is installed at `/Applications/Xcode.app`. `xcode-select` still points at the Command Line Tools, so run builds with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, or run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once. The app and keyboard build and the engine tests pass on the iOS 27 simulator.
- **Dictionaries:**
  - The keyboard now memory-maps `shala.tsv`, `kk_words.txt`, `ru_words.txt` and `autocorrect_allowlist.txt` (`SortedLinesFile`).
  - Regenerate them with `python3 scripts/build_dictionaries.py` after changing `ShalaqazaqDatasetV2.json`, `qazaqWordsList.txt`, `russianWordsDataset.txt` or `specs/data/autocorrect-conflicts.tsv`. Those source files stay in the repo but are no longer bundled.
- **Autocorrect rules:** `AutocorrectPolicy` (engine module) never replaces a real Kazakh or Russian word unless it's on the allow-list, and hides fragments.
- **Undo, learning, ignoring:** `QazaqActionHandler` (keyboard) does undo on backspace. Learned, refused and ignored words live in `PersonalStore`, which uses the keyboard's own UserDefaults. "Reset learned words" in Settings works through the app-group key `personalStoreResetToken`.
- **Russian protection:** `RussianSpellChecker` uses `UITextChecker` (ru_RU).
- **Versions:** the build number comes from `CURRENT_PROJECT_VERSION` (now 2 for the app and the keyboard). The keyboard's marketing version is aligned to the app (1.1.3); bump both to 1.2.0 when releasing.
- **Device QA still to do** (fix spec §4.2): undo on backspace (Q3), Russian protection (Q5), memory gauge (Q11), and whether the keyboard can save learned words without Full Access.

## 5. Predictive text v1 (2026-11-24)

A statistical language model: counts of words and word pairs, not a neural network. It runs offline and works without Full Access.

- **Data:**
  - `complete_kk.tsv`, `complete_ru.tsv` (completion), `prefix_top.tsv` (top words for 1–3 letter prefixes) and `next_words.tsv` (next word, with sentence starters per language) in `WordSuggestionsEngine/.../Recources`. They're memory-mapped, about 24 MB on disk; peak memory about 5 MB; about 0.1 ms per completion (macOS).
  - Built from Kazakh Wikipedia plus the first part of Russian Wikipedia: `python3 scripts/build_frequencies.py --kk kkwiki-latest-pages-articles.xml.bz2 --ru ruwiki-latest-pages-articles1.xml-p1p224167.bz2` (about 4 minutes; dumps from dumps.wikimedia.org, not committed).
  - Everyday chat words are boosted from `scripts/data/chat_words.txt`; extend that list freely.
  - Wikipedia credit (CC BY-SA 4.0) is shown in Settings.
- **Code:**
  - `PredictiveText` (engine module): completions, including shala input ("кан" → қандай), plus next words.
  - `TypingContext`: the current word, the previous word, and whether it's a sentence start.
  - `QazaqAutocompleteProvider` fills the bar: as typed, then the autocorrection, then the most frequent completions. After a space it shows the three likeliest next words.
- **Known limits:** Wikipedia is formal. Next-word suggestions after chat phrases are weak (after "қалайсың": none; after "сәлем": береді…). The fix is a chat-style corpus and counting the user's own words on the phone (design Phase 2).

## 6. Measuring users without Full Access (2026-11-24)

- **The keyboard leaves proof.** On every launch with Full Access, it writes `keyboardFullAccessLastSeen` (a date) to the app group (`KeyboardStatusReporter.markFullAccessIfGranted`). Without Full Access, iOS blocks that write, so the mark is proof.
- **The app reports `keyboard_status`** at most once a day when it becomes active (`AppDelegate`). Properties:
  - `isKeyboardEnabled`
  - `isOnboardingFinished`
  - `fullAccessConfirmed`: the keyboard's mark exists
  - `fullAccessLastSeenDaysAgo`
  - `fullAccessSystemFlag`: KeyboardKit's in-app check, kept to compare with the mark
- **The app and the keyboard now share one Amplitude device ID** (app-group key `sharedAnalyticsDeviceId`), so keyboard events and app events count as the same user.
- **In Amplitude:**
  - Full Access share = users with `fullAccessConfirmed = true` ÷ users with `isKeyboardEnabled = true`.
  - Users without Full Access = keyboard-enabled users minus that.
  - Real keyboard active users ≈ `launch_keyboard` users ÷ the share.
- **Limit:** only counts people who open the app at least once on this version.

## 7. New onboarding (2026-11-24)

- **Flow:** Welcome → Add keyboard → Try it → Done, with progress dots and one primary button at the bottom (`OnboardingView` is the shared template).
- **Old pages:** the long-press tutorial page and the Magic Auto-Correction page are gone. The long-press tip now lives on "Try it", and auto-correction is on by default (the switch is in Settings).
- **Add keyboard (`NewKeyboardSetupView`):**
  - It draws the two steps in Settings (Keyboards → turn on Batyrma).
  - It shows help right away when the user returns from Settings without the keyboard.
  - It has "Do it later", which leads to the main screen with an "Add the keyboard" banner.
  - It never mentions Full Access. The manual guide's Full Access step was removed too.
- **Events:**
  - Page views: `onboarding_welcome`, `onboarding_keyboard_setup`, `onboarding_try_it`, `onboarding_finish`.
  - New: `onboarding_try_it_success` (the keyboard restored a Kazakh letter), `setup_settings_opened`, `setup_returned_without_keyboard`, `setup_keyboard_detected`, `setup_postponed`.
  - `onboarding_alternative_char_long_press` and `onboarding_magic_autocorrection` are no longer sent.
- **QA:** in Debug builds, launch with the environment variable `ONBOARDING_PAGE=welcome|keyboardSetup|tryIt|finish` to open that page, e.g. `SIMCTL_CHILD_ONBOARDING_PAGE=tryIt xcrun simctl launch …`.
- **Build note:** the `Qazaqsha` scheme builds in **Release** by default. Pass `-configuration Debug` for Debug-only code.

## 8. Conversational onboarding (Opal-style), 2026-11-24

Replaces the §7 page designs (same 4 pages, same view model and page events).

- **Look:** always dark (`preferredColorScheme(.dark)` on `OnboardingView`), blue/gold glow (Kazakh flag colours), Batyrma's icon as a breathing "orb", thin progress bar, one white pill button that appears only after Batyrma finishes talking (`OnboardingViewModel.isPageReady`).
- **Voice:** Batyrma talks in the first person, mixing Kazakh and Russian the way users write. Each line is typed in shala (`Shala.fold`) and every word is corrected when finished, with restored letters in blue and a soft haptic. Russian words are left alone, which shows the bilingual support. Tap skips the animation; Reduce Motion shows lines at once. Engine: `TypedLinesView` in `OnboardingChat.swift` (lines may only be appended).
- **Welcome:** intro (Сәлем, қалайсың? → Менің атым Batyrma → қазақша да, и на русском → таза қазақша жазуға көмектесемін → Привычкаларыңды бұзбай 😉), then "Сен әдетте қалай жазасың?" with answers Қазақша / По-русски / Аралас. The answer replaces the "Get started" tap, gets a reply, and is sent as `onboarding_writing_style` {style: kazakh|russian|mixed} (also saved in `UserDefaults.standard["onboardingWritingStyle"]`).
- **Add keyboard (`SetupOnboardingView`):** looping screen recording of the real setup (asset-catalog data set `setup_video`, 7.6 s, 150 KB, no audio; source: founder's screen recording trimmed to the Settings part). Batyrma adds a help line if the user returns without the keyboard and celebrates when it's detected. The main-screen sheet (`NewKeyboardSetupView`) shows the same video.
- **Try it / Done:** same conversation style; success line when the first Kazakh letter appears.
- The chat copy is not localized on purpose (it is the product demo); buttons are.
- Unused now: strings `onboarding_welcome_title`, `onboarding_offline`, `setup_steps_header`, `onboarding_try_title`, `onboarding_try_subtitle`, `onboarding_try_success`, `onboarding_try_tip`.

## 9. Home, skins, stats, privacy page, sponsor pitch (2026-11-24)

- **Onboarding** is now welcome → **privacy** → add keyboard → try it → done. The privacy page (`PrivacyOnboardingView`, event `onboarding_privacy`) says Batyrma never reads/keeps/sends what you type and that iPhone's Full Access alert is standard text for every keyboard. Claims checked against the code: the keyboard sends only the daily `launch_keyboard` (settings flags, plus the last active day's open count and seconds on screen as `prevDayOpens` / `prevDayVisibleSeconds`, numbers only, `KeyboardUsageCounter`) plus Crashlytics crash/memory data. Re-check before adding any keyboard analytics.
  The welcome intro shows "Tap to skip" while typing. The done page has the skin picker.
- **Home (`MainView`)**: dark, same voice. Greeting → status (setup video + Open Settings while the keyboard isn't added; "Batyrma is on" after) → practice field → skins → stats → privacy card → sponsor card → More list → version/credit. Magic Auto-Correction lives only in Settings now. QA (Debug): `ONBOARDING_PAGE=main`, plus `HOME_SCREEN=bottom|sponsor`.
- **Skins**: catalogue `QazaqFoundation/Recources/KeyboardSkin.swift` (colours/gradients only; no images, for keyboard memory). Free: Classic, Түн, Көк. Paid pack `com.almagambetov.daulet.qazaqsha.skins.steppe` (Дала, Көк Тәңір, Ақ боз, Алтын). Limited `…skins.nauryz2027` (sold in March only; owners keep it).
  - The app (`SkinStore`, StoreKit 2) writes `keyboardSkinId` and `ownedSkinProducts` to the app group. The keyboard reads them in `viewWillAppear` (`SkinStyleService`, subclass of KeyboardKit's StandardStyleService), so skins work without Full Access.
  - Paid skins show "Soon" until the products exist in App Store Connect.
  - Events: `skin_selected`, `skin_purchase_started`, `skin_purchased`, `skin_purchase_cancelled`.
- **Stats**: `TypingStats` (QazaqFoundation). The keyboard counts applied autocorrections and restored Kazakh letters (numbers only) into the app group, so this works only with Full Access. The home shows this month's letters, total words and a Share button that opens `StatsShareSheet` (`StatsShareCard.swift`): a 1080×1920 story card rendered with ImageRenderer (big letter count, "калайсын → қалайсың" example, tagline, App Store line; content kept clear of the stories UI at top and bottom), shared via the system share sheet, since Instagram Stories/TikTok direct APIs need a Meta app ID / TikTok SDK. Events: `home_stats_card_opened`, `home_stats_shared` (param `destination` = share extension id). `GlobalConstants.appStoreURL` is nil until the App Store id is filled in. Known gap: an undone autocorrection is still counted.
- **Sponsor pitch (`SponsorPitchView`)**: opened from the home sponsor card; event `sponsor_pitch_opened`. Shows metrics, why Batyrma, placements (home card; a free branded skin) and "Become a supporter", which opens the #ads Telegram form. The metrics are typed by hand in `SponsorMetrics.current`: rates only, never audience size (next-day return 79%, still typing after a week 60%, 4.2 days a week, 39 opens a day; Amplitude Nov 17–23 2026; minutes on screen appears once 2.0 data exists). How each is computed is documented on the struct. Update them before each release. The "Become a supporter" form (`FeedbackView(type: .advertising)`) offers exactly two things: a keyboard skin in the brand's colours and the company's name on the space bar; Batyrma Plus isn't built, so it isn't offered.
- **Sponsor copy framing** (from a marketing review, Nov 2026): support for the Kazakh language, never "advertising": no advertis*/ads/реклама/жарнама in any user-facing string. Words: supporter / демеуші / партнёр, verb қолдау / поддержка. Sell meaning + daily habit, not reach (audience size is hidden). Pitch order: why (mission, trust, habit) → metric tiles → where your name appears (space bar, style, home card) → 0-characters tile → data note → CTA. The form has no emoji; the founder replies personally.
- **Keyboard styles look (Nov 2026)**: Apple-style palettes (quiet, desaturated; one accent on Return), not saturated flag colours. The suggestion bar takes the skin's colour scheme (`SkinStyleService.toolbarColorScheme`, applied in `KeyboardViewController.viewWillSetupKeyboardView`), because its `.primary` text followed the host app's dark mode and vanished on light skins. Picking a style in the app closes the open keyboard so the new style shows on the next open.
- **App Store screenshots**: `scripts/appstore/render_screenshots.swift` frames real captures (`AppStore/2.0/raw`) into 1320×2868 panels (`AppStore/2.0/screenshots-6.9 (large)/<localization>`), plus 1206×2622 copies in `screenshots-6.3 (required)`: App Store Connect requires the medium Dynamic Island size (1206×2622 or 1179×2556), and 1320×2868 is accepted only in the optional large slot: Kazakh → English (U.K.) (the KZ storefront's language), Russian → ru, English → en-US. Captures come from the Debug app on an iPhone 6.9" simulator via QA env: `ONBOARDING_PAGE`, `KEYBOARD_SKIN=<id>`, `HOME_PRACTICE=<text>` (focuses the practice field, fills it in; also skips the rating prompt). Metadata: `AppStore/2.0/metadata.md`.
- **Keyboard sponsor credit**: `KeyboardSponsor.brandName` (QazaqFoundation/Recources/KeyboardSkin.swift) puts "<brand> қолдауымен" on the space bar, dimmed (`SkinStyleService`). nil by default, and then the space bar says "Демеуші болыңыз" (be a sponsor); set it only with a signed sponsor. Plain text, never a link (App Review 4.4.1: keyboards can't open other apps or repurpose keys); ships in the build so it works offline and without Full Access.
