# Fix spec: critical, high and quick medium issues

_Date: 2026-11-23 · Targets: release 1.2.0 (fixes) and 1.3.0 (polish)_
_Related: [`../PRODUCT_STRATEGY.md`](../PRODUCT_STRATEGY.md) (the audit) · [`02-bilingual-prediction-design.md`](02-bilingual-prediction-design.md) (the new engine)_

This spec covers every **Critical** and **High** issue from the audit, plus the **Medium** issues that are cheap to fix. Word completion, next-word prediction and real Russian support are designed separately in `02-bilingual-prediction-design.md`. This spec only includes the stopgaps that can ship now.

## 0. Overview

### 0.1 What this spec is based on (verified on 2026-11-23)
- **The engine was compiled and run on real words.** Correct words such as ол, бар, сен, болу and барамын get replaced on space. Details are in `PRODUCT_STRATEGY.md`, Appendix A.
- **The full list of conflicts is in [`data/autocorrect-conflicts.tsv`](data/autocorrect-conflicts.tsv).** These are 311 words that are in the Kazakh word list but get auto-replaced. Each row has a proposed action:
  - 275 rows are "keep": protect the typed word.
  - 36 rows are "autocorrect": typed forms that are really misspellings.
  - The proposals are drafts by a non-native speaker and **must be reviewed**.
- **Only 346 of the 36,895 map entries are dictionary words.** So protecting dictionary words keeps about 99% of today's wanted corrections.
- **A score of 0.95 is used on purpose as a "never auto-apply" marker.** It's on vulgar words (жәлеп, боқмұрын, сігіп…) and on "казак". The current `> 0.95` check honours that, so **the threshold must stay `> 0.95`.**
- **Memory, measured on macOS with `/usr/bin/time -l`:**
  - Loading today's dictionaries takes the peak memory footprint from 1.8 MB to **37.4 MB**.
  - A prototype that maps sorted files from disk gives the same answers at **2.7 MB peak**, at **0.18 µs per lookup**.
- **KeyboardKit 9.0.8 hooks used below:**
  - `KeyboardAction.StandardActionHandler` and its `open` methods: `handle(_:on:replaced:)`, `tryApplyAutocorrectSuggestion(before:on:)`, `shouldApplyAutocorrectSuggestion(before:on:)` and `handle(_ suggestion:)`.
  - `Autocomplete.Settings.isAutolearnEnabled`, which defaults to `false`.
  - `autocompleteText`, which is `documentContextBeforeInput`.

### 0.2 Items
| ID | Item | Release | Effort |
|---|---|---|---|
| C1 | Stop replacing correct words (autocorrect rules) | 1.2.0 | M (2–3 days) |
| C2 | Undo on backspace, learn and ignore words | 1.2.0 | M (2 days) |
| C3 | Hide fragments that aren't words (real completion is in the design doc) | 1.2.0 | S (½ day) |
| C4 | Russian: protect valid Russian words now, suggest them in 1.3.0 | 1.2.0 / 1.3.0 | S + M |
| C5 | Memory: map dictionaries from disk; take Amplitude and the GIF library out of the keyboard | 1.2.0 | M (2–3 days) |
| C6 | Ship again (Xcode 26, build number) | 1.2.0 | S–M |
| H1 | Emoji keyboard | 1.3.0 | M–L (3–5 days) |
| H2 | ₸ sign | 1.2.0 | S |
| H3 | Remove the "б" easter egg | 1.2.0 | S |
| H4 | Fix Kazakh and Russian UI text | 1.2.0 | S (+ native review) |
| H5 | Fix the Kazakh privacy-policy link | 1.2.0 | S |
| H6 | One brand name | 1.2.0 (store) / 1.3.0 (assets) | S |
| H7 | Remove the "BETA" labels | 1.2.0, after C1, C2 and C5 pass QA | S |
| H8 | Clean Latin look-alike letters out of the dictionaries | 1.2.0 | S |
| M1 | Remove the 3-second fake loading screen | 1.2.0 | S |
| M2 | Make Full Access optional and explain it | 1.3.0 | S |
| M3 | Keyboard status card and try-it field on the main screen | 1.3.0 | M |
| M4 | Ask for a review after a good moment | 1.3.0 | S |
| M5 | Clean up Info.plist and the build number | 1.2.0 | S |
| M6 | Make the privacy text match the App Store privacy label | 1.2.0 | S |
| M7 | Analytics: throttle `launch_keyboard`, add setup-funnel and quality events | 1.3.0 | M |
| M8 | Fix the iOS version check | 1.2.0 | S |
| M9 | Remove dead code and debug prints | 1.2.0 | S |

S = up to 2 hours · M = 1–3 days · L = 3–5 days, at part-time pace.

### 0.2a Implementation status (2026-11-23)
| Status | Items |
|---|---|
| ✅ Done in code, covered by tests | C1, C3, C5 (dictionaries mapped from disk; peak memory 37.4 → 3.1 MB on macOS), H2, H3, H5, H8, M1, M5, M8, M9 (except deleting the commented-out `FirebaseService.swift`) |
| ✅ Done in code, **needs device QA** | C2 (undo on backspace, learn, ignore, "Reset learned words" in Settings), C4(a) (Russian check via `UITextChecker`), C6 (builds on Xcode 27 / iOS 27 SDK; build number now `$(CURRENT_PROJECT_VERSION)`; keyboard version aligned to the app) |
| ✅ Done, **needs native review** | H4 Kazakh text; the allow-list (only the 26 "high" rows are active; the 10 "verify" rows aren't) |
| ⏳ Partly done | M7: `launch_keyboard` is now sent at most once a day, with a `hasFullAccess` property. Setup-funnel events are not added yet. |
| ⏳ Not started | H1, H6 (brand decision), H7 (after QA), M2, M3, M4, M6, C4(b); splitting `QazaqFoundation` so Amplitude isn't linked into the keyboard (it's now only created once a day) |

### 0.3 Release plan
- **1.2.0, "it stops fighting you"** (about 2 weeks part-time): C1, C2, C3, C4 part (a), C5, C6, H2–H5, H7, H8, M1, M5, M6, M8, M9, plus the App Store part of H6.
- **1.3.0, "it feels complete"** (about 3–4 weeks part-time): H1, C4 part (b), M2, M3, M4, M7, plus the asset part of H6.
- **2.0, bilingual engine:** see `02-bilingual-prediction-design.md`.

---

## 1. Critical

### C1. Stop replacing correct words
**Problem.** Pressing space after a correct, common word replaces it. Examples: ол→өл, бар→бәр, сен→сең, болу→бөлу, туралы→тұралы, орын→орың, канал→қанал. 311 dictionary words are affected.

**Root cause.**
- `findVariations` (`WordSuggestionsEngine.swift:68-79`) looks the typed word up in the Russian-letters→Kazakh map *first*. It only checks "is this already a Kazakh word?" third.
- The provider marks anything above 0.95 as `.autocorrect` (`QazaqAutocompleteProvider.swift:62`).
- KeyboardKit applies that on space.

**Design.**
1. **The engine reports where each candidate came from.**
   ```swift
   public enum MatchKind: Equatable {
       case exactKey                 // typed word is a key in the map
       case alteredRoot              // key found after reversing a consonant change (ғ→қ, б→п, г→к)
       case rootWithGeneratedEnding  // start of word matched; ending rebuilt by QazaqEndingsGenerator
       case rootWithRawSuffix        // start matched, ending NOT rebuilt (today's 0.9 fallback) → a fragment
       case kazakhWord, russianWord  // typed word itself is in a list
   }
   public struct GeneratedSimilarWord: Equatable {
       public let word: String
       public let similarity: Double
       public let kind: MatchKind
   }
   ```
   Set `kind` in `QazaqWordSuggestionsEngineV2.suggestWords`. Where `generateTazaOutput` returns nil (`WordSuggestionsEngine.swift:39-45`), the kind is `.rootWithRawSuffix`.

2. **New `AutocorrectPolicy`.** It's pure Swift in the `WordSuggestionsEngine` module, so it can be unit-tested. The provider calls it for every candidate:
   ```swift
   enum Decision { case autocorrect, suggest, hide }

   struct AutocorrectPolicy {
       let isKazakhWord: (String) -> Bool      // dictionary lookup (C5 format)
       let isRussianWord: (String) -> Bool     // UITextChecker ru_RU, falling back to a word list (C4)
       let allowList: Set<String>              // reviewed rows of data/autocorrect-conflicts.tsv
       let personal: PersonalStore             // C2

       func decide(typed: String, candidate: GeneratedSimilarWord, isSentenceStart: Bool) -> Decision {
           let t = typed.lowercased()
           if candidate.kind == .rootWithRawSuffix { return .hide }                   // C3
           if personal.isIgnored(candidate.word) { return .hide }
           if personal.isLearned(t) || personal.isRejected(t, candidate.word) { return .suggest }
           if typed.first?.isUppercase == true && !isSentenceStart { return .suggest } // probably a name (Куаныш, Жанар)
           if allowList.contains(t) { return .autocorrect }                           // reviewed misspellings, incl. казак
           if isKazakhWord(t) || isRussianWord(t) { return .suggest }                 // protect real words
           return candidate.similarity > 0.95 ? .autocorrect : .suggest               // keep > 0.95 (0.95 = never auto)
       }
   }
   ```

3. **Provider changes** (`QazaqAutocompleteProvider.suggestions(for:)`):
   - Map each candidate through the policy and drop `.hide`.
   - Mark only the first `.autocorrect` candidate as `.autocorrect`; all others become `.regular`. Keep the typed word as the first suggestion (type `.unknown`).
   - Pass `isSentenceStart`: true when the text before the word is empty or ends with `.`, `!`, `?` or a newline.

4. **Data.**
   - Review `data/autocorrect-conflicts.tsv` (about 30 minutes for a native speaker).
   - Write the confirmed "autocorrect" rows to `WordSuggestionsEngine/.../Recources/autocorrect_allowlist.txt`, one word per line.
   - Remove those misspellings from `qazaqWordsList.txt`, because they aren't real words (жаксы, орталык, калган…).

**Acceptance criteria.**
- No "keep" row in the TSV is auto-replaced. Every confirmed allow-list row is.
- These still auto-correct: салем→сәлем, кандай→қандай, калайсын→қалайсың, жаксы→жақсы, бугин→бүгін, ертен→ертең, казак→қазақ.
- Russian words with a Kazakh look-alike stay as typed: кит, канал, колхоз, сценарий, дал, дам.
- Vulgar entries scored 0.95 are never auto-applied.
- A capitalised word in mid-sentence is never auto-replaced.

**Tests** (in `WordSuggestionsEngineTests`, table-driven from fixtures):
- `test_keepRows_neverAutocorrect()` reads the TSV and runs the policy on every "keep" row.
- `test_allowList_autocorrects()`
- `test_shalaExamples_stillAutocorrect()`
- `test_russianLookalikes_neverAutocorrect()`
- `test_capitalizedMidSentence_suggestOnly()`
- `test_threshold_095_isSuggestOnly()`

---

### C2. Undo on backspace, learn and ignore words
**Problem.**
- `ignoreWord`, `learnWord` and related methods do nothing (`QazaqAutocompleteProvider.swift:29-39`).
- Backspace doesn't bring the original word back. Retyping it gets it replaced again.
- KeyboardKit's autolearn is off by default.

**Design.**
1. **`PersonalStore`**, in the keyboard target:
   - Stored in the keyboard's own `UserDefaults.standard`. It never leaves the phone.
   - Holds `learned: [String: Int]` (word → count), `rejected: Set<String>` (pairs written `typed→candidate`) and `ignored: Set<String>`.
   - Size caps: 5,000 learned words and 2,000 rejected pairs, with least-recently-used eviction.
   - **Verify on iOS 26 and 27 that the keyboard can write without Full Access.** If writes fail, keep the store in memory for the session. When Full Access is on, also mirror it to the app group.
   - **"Reset learned words" in the app's Settings.** The app sets a flag in the app group. The keyboard reads it on launch (reading the app group works without Full Access) and clears its store.
2. **Provider:**
   - Set `canIgnoreWords = true` and `canLearnWords = true`.
   - Back `learnedWords`, `ignoredWords`, `learnWord`, `ignoreWord`, `unlearnWord` and `removeIgnoredWord` with the store.
3. **Turn on autolearn:** in `KeyboardViewController.setupKeyboardServices()`, set `state.autocompleteContext.settings.isAutolearnEnabled = true`. Tapping the typed-word suggestion (type `.unknown`) then calls `learnWord`.
4. **Undo on backspace, Gboard-style.** The first backspace right after an autocorrection restores the typed word.
   ```swift
   final class QazaqActionHandler: KeyboardAction.StandardActionHandler {
       private var lastAutocorrection: (original: String, replacement: String)?
       let store: PersonalStore

       override func tryApplyAutocorrectSuggestion(before gesture: Keyboard.Gesture, on action: KeyboardAction) {
           let original = keyboardContext.textDocumentProxy.currentWordPreCursorPart
           let suggestion = autocompleteContext.suggestions.first { $0.isAutocorrect }
           let willApply = suggestion != nil && shouldApplyAutocorrectSuggestion(before: gesture, on: action)
           super.tryApplyAutocorrectSuggestion(before: gesture, on: action)
           if willApply, let original, let suggestion, original != suggestion.text {
               lastAutocorrection = (original, suggestion.text)
           }
       }

       override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction, replaced: Bool) {
           let proxy = keyboardContext.textDocumentProxy
           if gesture == .press, action == .backspace, let last = lastAutocorrection,
              proxy.documentContextBeforeInput?.hasSuffix(last.replacement + " ") == true {
               for _ in 0..<(last.replacement.count + 1) { proxy.deleteBackward() }
               proxy.insertText(last.original)          // "өл␣" → "ол", cursor right after it
               store.reject(last.original, last.replacement)
               store.learn(last.original)
               lastAutocorrection = nil
               return                                     // this backspace is used up by the undo
           }
           if action != .space { lastAutocorrection = nil } // any other key cancels the undo window
           super.handle(gesture, on: action, replaced: replaced)
       }
   }
   ```
   Install it in `setupKeyboardServices()` *after* the autocomplete service is set: `services.actionHandler = QazaqActionHandler(controller: self, store: store)`.
   - Add a convenience initialiser that calls `super.init(controller:)`.
   - Check that `.space` itself doesn't clear the undo window. The window has to survive the space press that triggered the autocorrection.

**Acceptance criteria.**
- After any autocorrection, one backspace restores the typed word without a trailing space. Typing space again does not re-apply the correction, and this persists after the keyboard reloads.
- Tapping the typed-word suggestion inserts it, and from then on it's never auto-replaced.
- "Reset learned words" in the app clears everything the next time the keyboard opens.

**Tests.**
- Unit tests for `PersonalStore`: caps, eviction, persistence.
- Unit tests for the policy together with the store.
- Manual QA scenarios Q3 and Q4 in section 4.

---

### C3. Hide fragments now; real completion comes with the new engine
**Problem.**
- Partway through a word the bar shows things that aren't words: канд→"кәнд / қанд", кал→"кәл / қал".
- There's no completion ("мек" never suggests мектеп) and nothing is suggested after a space.

**Fix in 1.2.0.**
- The C1 policy hides `.rootWithRawSuffix` candidates.
- Show no candidates when the typed word is a single letter.
- Generated forms from a dictionary root (`.rootWithGeneratedEnding`, e.g. қазағым) stay as suggestions.

**Full fix:** word completion and next-word prediction are Phases 1–2 of `02-bilingual-prediction-design.md`.

**Acceptance criteria.** Typing "канд" never shows "кәнд" or "қанд". Typing "кан" may show "қан", which is a real word.

---

### C4. Russian: protect valid words now, suggest them in 1.3.0
**Problem.**
- Russian only has a 1,982-line list of dictionary-form words, used as a fallback.
- Russian words get no suggestions.
- Some Russian words are auto-replaced with Kazakh look-alikes, for example "кит" (whale) → "қит".

**(a) 1.2.0: protect Russian words.**
- `isRussianWord(_:)` uses `UITextChecker().rangeOfMisspelledWord(in:range:startingAt:wrap:language: "ru_RU")`. A result of `NSNotFound` means the word is spelled correctly, so it's a valid Russian word.
- Fallback when `ru_RU` is missing from `UITextChecker.availableLanguages`: a sorted list of Russian word forms in the C5 format, for example the top ~100k forms from an open frequency list (check its licence).
- C1's policy then protects these words.
- **Verify on a device:** that it works inside the keyboard extension, plus its speed (target under 1 ms per check) and memory cost.

**(b) 1.3.0: Russian suggestions.**
- When the current word looks Russian (it contains ё, ъ, щ or э, or it's a valid Russian prefix and not a Kazakh one), fill one bar slot from `UITextChecker.completions(forPartialWordRange:in:language: "ru_RU")`.
- After a space, nothing until the new engine.

**Acceptance criteria.**
- "кит␣", "канал␣" and "дал␣" stay as typed.
- In 1.3.0, typing "приве" shows "привет".

---

### C5. Memory: map dictionaries from disk instead of decoding them
**Problem.**
- iOS kills the keyboard silently and swaps in the system keyboard.
- The current loader decodes a 2.1 MB JSON into Swift dictionaries (two copies at peak) and builds a `Set` of 54k strings. Measured peak: **37.4 MB** against a 1.8 MB baseline.
- Firebase, Amplitude and FLAnimatedImage (pulled in through `QazaqFoundation`) also load into the keyboard.
- The keyboard limit is roughly 48–70 MB (unofficial).

**Design.**
1. **Build step.** Add `scripts/build_dictionaries.py`, run by hand whenever the data changes, with its outputs committed. It writes:
   - `shala.tsv`: sorted by UTF-8 bytes, one line per entry: `key\tword:score|word:score`.
   - `kk_words.txt`: sorted, unique, look-alikes cleaned (H8), allow-list misspellings removed (C1).
   - `ru_words.txt`: the C4 fallback.
   - Remove `ShalaqazaqDatasetV2.json` from the keyboard bundle.
2. **`SortedLinesFile`.** Map the file with `Data(contentsOf:options: .alwaysMapped)`. Build a `[UInt32]` array of line starts once (about 0.4 MB for 91k lines). Binary-search on the key bytes. This is the prototype code from the measurement, at `/private/tmp/claude-501/-Users-daukabase-NeoQazaq/5d87423a-60a3-43f0-8a3e-eb3e2a3a4d35/scratchpad/mmapproto/main.swift`, a temporary folder that may be cleared.
3. **`QazaqWordsDatasetLoader`.**
   - Replace the dictionary and sets with `variations(for:)`, `containsKazakhWord(_:)` and `containsRussianWord(_:)`.
   - Mapping is instant, so the `Task`s and `serialQueue` go away. This also fixes having no suggestions during the first keystrokes.
   - Update the callers in `WordSuggestionsEngine.swift` (lines 69, 91, 99, 106).
4. **Slim down the keyboard.**
   - Split `QazaqFoundation` into **QazaqCore** (UserDefaults keys, string helpers; linked by the keyboard and the app) and **QazaqUI** (GIF, SwiftUI helpers, Amplitude; app only).
   - Remove `AmplitudeSwift` from the Batyrma target.
   - Keep Crashlytics and `MemoryPressureMonitor`.
5. **Remove the debug `print`s from the `currentBundle` getter** (`QazaqWordsDatasetLoader.swift:31-35`). It prints on every access.
6. **Monitoring.** Add Crashlytics custom keys for the memory footprint at launch and after the first suggestion.

**Acceptance criteria.**
- On an iPhone SE (2nd/3rd generation) or iPhone 11, the keyboard's memory in Xcode's gauge stays **under 30 MB** after typing two sentences.
- The rate of memory-pressure reports in Crashlytics for the 1.2.0 users is **at least 80% lower** than for 1.1.x.
- Same suggestions as before, apart from the intended C1 changes.

**Tests.**
- `SortedLinesFile` unit tests: lookups of the first, last, missing and Cyrillic keys.
- A parity test that compares the old and new loaders across all 36,895 keys, run once and then removed.

---

### C6. Ship a build again
**Problem.** The App Store rejects uploads that aren't built with the iOS 26 SDK. The build number is hard-coded to `1` (`Qazaqsha/Info.plist:39`).

**Steps.**
1. Install Xcode 26.x next to 16.4 and select it with `xcode-select` (the steps are in `CONTEXT.md`).
2. Fix compiler and package issues. Check the KeyboardKit 9.x, Firebase and Amplitude release notes for iOS 26 SDK support.
3. Set `CFBundleVersion = $(CURRENT_PROJECT_VERSION)` in the app and in the extension, and bump it on every upload.
4. **Liquid Glass:** for 1.2.0, set `UIDesignRequiresCompatibility = YES` to keep the scope small. Adopt the new look in a later release.
5. Run the TestFlight smoke test (section 4) on iOS 16, 17, 18, 26 and 27.

**Acceptance criteria.** The build is processed with the iOS 26 SDK, and TestFlight installs and runs on the device matrix.

---

## 2. High

### H1. Emoji keyboard (1.3.0)
**Problem.** There's no emoji keyboard; the setting says "coming soon" (`SettingsView.swift:46-52`). Users have to switch keyboards for every emoji. In KeyboardKit, the emoji keyboard needs a paid Pro licence.

**Options.**
- **A) KeyboardKit Pro.** Fastest and polished. It's a yearly cost; check the current price.
- **B) Build a small one (recommended if budget is tight).**
  - Data: Unicode's `emoji-test.txt` (fully-qualified emoji, already grouped; permissive Unicode licence), converted to a ~60 KB file.
  - UI: a SwiftUI `LazyHGrid` of `Text(emoji)` with category tabs, an ABC key and a backspace key.
  - Recents: the last 30 emoji, stored in the keyboard's UserDefaults.
  - Show emoji as text in the system font. Don't bundle Apple emoji images. Rule 4.4.1 requires following the sticker guidelines when a keyboard includes emoji.

**Acceptance criteria.**
- The emoji key opens the grid; tapping an emoji inserts it; recents persist; the ABC key returns.
- Scrolling through every category keeps memory under 35 MB.

### H2. Tenge sign ₸ (1.2.0)
- In `CyrillicService.swift:13`, change `numericInputSet: .numeric(currency: "$")` to `.numeric(currency: "₸")`.
- Change the symbols page to `.symbolic(currencies: ["$", "€", "₽"])`.
- In `QazaqCalloutService.calloutActionString`, add `case "₸": return "₸$€₽£¥"` and change the `$` callout to `"$₸€₽£¥¢₩"`.
- **Acceptance criteria:** ₸ shows on the 123 page, and long-pressing it offers the other currencies.

### H3. Remove the "б" easter egg (1.2.0)
- Delete `case "б": return String("брат".reversed())` at `QazaqCalloutService.swift:46`.
- **Acceptance criteria:** long-pressing б shows no callout.

### H4. Fix the Kazakh and Russian UI text (1.2.0)
| Key | Locale | Now | Proposed (Kazakh needs native review) |
|---|---|---|---|
| `onboarding_alternative_chars_bullet_1` | kk | Альтернатив әріпі бар пернесін узақ басу | Қосымша әріптері бар пернені ұзақ басып тұрыңыз |
| `onboarding_alternative_chars_bullet_2` | kk | Саусағынызды жылжытып пернені таңдау | Саусағыңызды керекті әріпке жылжытыңыз |
| `onboarding_alternative_chars_bullet_3` | kk | Саусағынызды таңдалған әріпті еңгізу үшін көтеру | Әріпті енгізу үшін саусағыңызды көтеріңіз |
| `onboarding_welcome %@` | kk | %@ қош келдіңіз | %@ қолданбасына қош келдіңіз |
| `onboarding_alternative_chars_bullet_1` | ru | Нажать и удерживать любую кнопку которая имеет скрытые буквы | Нажмите и удерживайте клавишу со скрытыми буквами |
| `onboarding_alternative_chars_bullet_2` | ru | Двигая пальцем выбрать букву | Проведите пальцем к нужной букве |
| `onboarding_alternative_chars_bullet_3` | ru | Отпустиить палец над выбранной буквой | Отпустите палец, чтобы вставить букву |

Then have a native editor proofread all 84 keys in `Resources/Localizable.xcstrings`, in Kazakh and in Russian.

### H5. Fix the Kazakh privacy-policy link (1.2.0)
- In `common_privacy_policy_content` (Kazakh), replace `https://www.freeprivacypolicy.com/blog/privacy-policy-url/` with the termsfeed policy URL that the English and Russian versions already use.
- **Acceptance criteria:** with the phone in Kazakh, the link opens the app's own policy.

### H6. One brand name
- **1.2.0, App Store:**
  - Listing name: "Batyrma — қазақша пернетақта".
  - Russian keywords in the subtitle and keywords field (казахская клавиатура, автозамена).
  - Screenshots that lead with the before/after.
- **1.2.0, app:**
  - `CFBundleDisplayName` = "Batyrma" (`Qazaqsha/Info.plist:13`).
  - Check the keyboard extension's display name, which is what appears in the iOS keyboard list.
- **1.3.0:** rename the `selectNeoQazaqKeyboard*` GIFs and any other "NeoQazaq" or "Qazaqsha" strings users can see.

### H7. Remove the "BETA" labels
- Remove the `common_beta_magic_autocorrection` footers in `MainView`, `SettingsView` and `MagicAutocorrectionView` once C1, C2 and C5 pass QA.

### H8. Clean Latin look-alike letters out of the dictionaries (1.2.0)
- In `build_dictionaries.py`, convert Latin letters that look Cyrillic: a→а, e→е, o→о, p→р, c→с, x→х, y→у, i→і, I→І, A→А.
- Then reject any entry that still contains `[A-Za-z]`. Today 28 entries have this problem, for example "aрқылы" and "алy".
- **Test:** `test_dictionaries_containNoLatinLetters()`.

---

## 3. Quick medium fixes

| ID | Change | Files | Acceptance |
|---|---|---|---|
| **M1** | Remove the 3-second `FakeLoadingView` delay and show onboarding straight away. If an animation is wanted, keep it under 0.5 s. | `OnboardingView.swift:35-41` | First onboarding screen appears in under 0.5 s |
| **M2** | Mark "Allow Full Access" as **optional** in the manual setup. Add an explanation sheet: "Adds key sounds/haptics and settings sync; your typing never leaves your phone." Show "needs Full Access" next to Key Click Sounds. | `ManualKeyboardSetupView.swift:117`, `SettingsView.swift` | Setup never implies that Full Access is required |
| **M3** | Status card on the main screen: keyboard enabled ✓/✗ (`GlobalConstants.isKeyboardExtensionEnabled`) and Full Access ✓/✗ (a flag the keyboard writes to the app group when it has Full Access). Add a **Try it** field. | `MainView.swift` | Status is correct after enabling or disabling in Settings |
| **M4** | Ask for a review only after a good moment: an autocorrection happened in the try-it field, **or** the app opens ≥ 3 days after onboarding while the keyboard is enabled. Remove the "every 3rd launch" rule. | `AppReviewService.swift`, `MainView.swift` | No prompt on the first or second app open without a good moment |
| **M5** | Delete `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`, the `kkdemo` URL scheme and `INIntentsSupported`. Change the legacy `armv7` capability to `arm64` or remove it. Build number: see C6. | `Qazaqsha/Info.plist:7,9,34,40` | Archive passes validation; no permission strings without a use |
| **M6** | Make `data_not_collected` accurate in all three languages, e.g. "Your typing never leaves your phone. We collect anonymous usage stats and crash reports to improve the app." Update the App Store privacy label: Identifiers (device ID), Usage Data, Diagnostics, Contact Info (only if given in feedback), Customer Support content. | `Localizable.xcstrings`, App Store Connect, privacy policy | Text, label and policy match |
| **M7** | Send `launch_keyboard` at most once per day (store the last-sent date). Add app events `settings_opened`, `keyboard_enabled_detected` and `full_access_detected`. Keyboard quality counters (suggestions shown and accepted, corrections applied and undone) come only with Full Access, once a day, as counts and **never text**. | `KeyboardViewController.swift:69-77`, app screens | Event volume drops; funnel charts possible |
| **M8** | Replace `UIDevice.current.systemVersion.hasPrefix("18")` with `ProcessInfo.processInfo.isOperatingSystemAtLeast(.init(majorVersion: 18, minorVersion: 0, patchVersion: 0))`. | `NewKeyboardSetupView.swift:37` | Troubleshooting tip also shows on iOS 26 and 27 |
| **M9** | Remove `MainViewModel.shouldRequestReview`, `AppReviewRequestManager`, the unused `faqSection`, the commented-out `FirebaseService.swift`, and the unused `donateProject` until monetisation ships. | `MainView.swift`, `FirebaseService.swift` | Builds with no behaviour change |

---

## 4. Test plan

### 4.1 Automated
- **Engine and policy:** the C1 tests, which read `data/autocorrect-conflicts.tsv`.
- **Personal store:** the C2 tests.
- **Dictionaries:** the `SortedLinesFile` tests, the one-time parity test, and the no-Latin-letters test.
- **CI** (later): run `WordSuggestionsEngineTests` on every push.

### 4.2 Manual QA script (TestFlight)
| # | Steps | Expected |
|---|---|---|
| Q1 | Type "ол бар сен болу туралы " | Nothing changes |
| Q2 | Type "салем калайсын жаксы " | сәлем қалайсың жақсы |
| Q3 | Type "казак " (auto-corrects to қазақ), then press backspace once | Shows "казак" with the cursor after it; pressing space keeps "казак" |
| Q4 | Tap the typed-word suggestion for a rare word, close and reopen the keyboard, type it again plus space | Kept as typed |
| Q5 | Type "Привет кит канал дал " | Nothing changes |
| Q6 | Type "канд" | No "кәнд" or "қанд" in the bar |
| Q7 | Mid-sentence, type "Куаныш " | Not auto-replaced |
| Q8 | Open the 123 page; long-press ₸ | ₸ is there, with other currencies in the callout |
| Q9 | Long-press б | No callout |
| Q10 | Phone in Kazakh: check onboarding text; tap the privacy link | Text fixed; link opens the app's own policy |
| Q11 | Type for 2 minutes and watch Xcode's memory gauge | Under 30 MB |
| Q12 | First launch | No 3-second loading screen |
| Q13 (1.3.0) | Emoji flow; Russian completion "приве" | Works; shows "привет" |

### 4.3 Device and OS matrix
- iPhone SE (2nd or 3rd generation, low memory), iPhone 11, a recent iPhone.
- iOS 16, 17, 18, 26 and 27.
- Test with Full Access on and off.

### 4.4 After release, watch
- The memory-pressure report rate in Crashlytics.
- The share of `launch_keyboard` events with `isAutocompleteEnabled = false`. It should fall as the autocorrect stops fighting users.
- Ratings and reviews.

---

## 5. Open questions (check on a device before coding)
1. Can the keyboard write its own `UserDefaults` **without Full Access** on iOS 26 and 27? This decides where C2 stores data.
2. Is `UITextChecker` with `ru_RU` available **inside the keyboard extension**, and how fast and heavy is it? This decides C4.
3. Does KeyboardKit 9.0.8 build with Xcode 26, or does it need an upgrade? (C6)
4. Keep the old look with `UIDesignRequiresCompatibility` for 1.2.0, or adopt Liquid Glass now?
5. Native-speaker review of `data/autocorrect-conflicts.tsv` and of the H4 text.
