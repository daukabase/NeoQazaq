# Batyrma (NeoQazaq): UX audit, bilingual keyboard plan, pricing and go-to-market

_Date: 2026-11-23 · Scope: the iOS app and keyboard extension in this repo_
_Specs: [`specs/01-fix-spec.md`](specs/01-fix-spec.md) (fixes) · [`specs/02-bilingual-prediction-design.md`](specs/02-bilingual-prediction-design.md) (bilingual engine) · [`specs/data/autocorrect-conflicts.tsv`](specs/data/autocorrect-conflicts.tsv) (311 words to review)_

**How this was produced**
- Read the whole codebase: keyboard extension, suggestion engine, app screens, analytics and datasets.
- Compiled `WordSuggestionsEngine` into a small command-line tool and ran real words through it (results in Appendix A).
- Checked Apple's iOS 27 language support, the App Review Guidelines, competitors, and Kazakhstan market data and prices (sources at the end).

**Data caveats**
- No Amplitude connector was attached to the session, so this report has no event data. The only usage number is the user-reported **~50% retention at day 14**. Which event defines it is unconfirmed.
- This app's own App Store page and reviews were not looked up, because that would send the app's identity to an outside scraping service.
- Labels used below: ✅ verified in the code or by running it · 🔎 verified from an outside source · ⚠️ assumption or estimate.

---

## Summary

1. ✅ **The worst problem: autocorrect replaces correct Kazakh words.** You type a common, correct word, press space, and it gets swapped. For example, **ол → өл** ("die!"), **бар → бәр**, **сен → сең**, **болу → бөлу**, and **барамын → барамың**, which isn't even a word. A scan of the dataset finds **311** real dictionary words affected. There is no undo, and retyping the word gets it swapped again.
2. 🔎 **The gap in the market is real.** Apple's iOS 27 feature list has no Kazakh predictive text, autocorrect, dictation or swipe typing. Apple's multilingual typing (one keyboard, two languages) supports neither Kazakh nor Russian. No iPhone keyboard predicts Kazakh and Russian in one layout. That is the product.
3. **50% retention at day 14 means people who finish setup keep using it.** The real bottlenecks are getting installs, the setup steps, and having no income at all.
4. 🔎 **Apple bans both selling data and showing ads inside a keyboard.** Use a free core plus a paid **Plus tier at ≈1,990₸/year or ≈4,990₸ lifetime**, with an AI tier later. Consumer income in Kazakhstan alone is modest (⚠️ about $10–40k a year). The bigger upside is licensing the engine to businesses and adding other languages Apple ignores.
5. **Marketing:** lead with "Шала жазсаң да, таза шығады" ("even if you type it sloppy, it comes out correct"), "the keyboard Apple never made for Kazakh", and the founder story. Relaunch at **Nauryz (March 21, 2027)** and push again on **Language Day (September 5)**.

---

## 1. What the app does today

**Keyboard (`Batyrma/`)**
- Built on KeyboardKit 9.0.8 with a Russian ЙЦУКЕН layout: rows "йцукенгшщзх", "фывапролджэ", "ячсмитьбю" (`QazaqCalloutService.swift:68-75`).
- Kazakh letters come from long-press: а→ә, о→ө, у→ұ/ү, к→қ, г→ғ, н→ң, ы/и→і, х→һ. Also е→ё and ь→ъ (`QazaqCalloutService.swift:33-46`).
- Locale is Kazakh. The edge margin keys next to я/ю are removed (`CyrillicKeyboardLayout.swift`).

**"Magic Auto-Correction", still marked BETA (`WordSuggestionsEngine/`)**
- **Data:**
  - 36,895 entries mapping words typed with Russian letters to proper Kazakh (`ShalaqazaqDatasetV2.json`, 2.1 MB).
  - A 54k-line Kazakh word list.
  - A 1,982-line Russian list in dictionary form. It contains duplicate blocks and junk such as "вызывать (See #663)".
- **Method:** find the longest start of the typed word that is in the map, then rebuild the ending with possessive and plural rules (`QazaqEndingsGenerator`).
- **Suggestion bar:** what you typed plus up to 2 candidates. Anything scored above 0.95 is applied automatically on space (`QazaqAutocompleteProvider.swift:55-71`).

**App (`Qazaqsha/`)**
- **Onboarding:** a 3-second fake loading screen → welcome → long-press demo → enable the keyboard in Settings → Magic Auto-Correction toggle and try-it field → "Say Сәлем!" with links to WhatsApp, Telegram, Instagram and TikTok.
- **Main screen:** Settings, Magic Auto-Correction, FAQ, Tech support, Collaboration (Telegram bot), Privacy Policy.
- **Settings:** auto-capitalisation, key click sounds, and an emoji key marked "coming soon".
- **Other:** review prompt; English, Kazakh and Russian UI.

**Analytics and infrastructure**
- Amplitude events: `app_start`, the five `onboarding_*` page views, and `launch_keyboard`. The last one carries the autocomplete, auto-caps and click-sound settings.
- Firebase Crashlytics runs in both the app and the keyboard, plus `MemoryPressureMonitor`.
- The keyboard asks for Full Access (`RequestsOpenAccess = true` in `Batyrma/Info.plist:19`).

**History**
- 148 commits: the first on 2024-01-29, the last on 2025-01-15.
- The current App Store upload is blocked: it must be built with the iOS 26 SDK (see `CONTEXT.md`).

---

## 2. UX blind spots

### Critical

| # | Issue | Evidence |
|---|---|---|
| 1 | ✅ **Correct words get replaced on space.** The engine checks its map *before* asking "is this already a real Kazakh word?", and anything above 0.95 is applied automatically. 311 real words are affected. | `WordSuggestionsEngine.swift:68-79`, `QazaqAutocompleteProvider.swift:62`; KeyboardKit's `StandardActionHandler.tryApplyAutocorrectSuggestion` applies it on space |
| 2 | ✅ **No undo and no learning.** "Ignore word" and "learn word" do nothing. The only escape is tapping the typed word in the bar every time, or switching the feature off. | `QazaqAutocompleteProvider.swift:29-39` |
| 3 | ✅ **No word completion and no next-word suggestions.** While typing, the bar shows fragments that aren't words ("кан" → кән / қан, "канд" → кәнд / қанд). "мек" never offers мектеп. Nothing is suggested after a space. | Appendix A; `QazaqAutocompleteProvider.swift:49` |
| 4 | ✅ **Russian is basically unsupported.** The 2k word list is only a fallback. "привет", "спасибо", "сегодня" get zero suggestions. Russian "кит" (whale) is auto-replaced with қит. Bilingual users keep switching keyboards. | `WordSuggestionsEngine.swift:75`, Appendix A |
| 5 | ✅ **Memory crashes.** iOS kills the keyboard silently and swaps in the system keyboard. The JSON file is decoded into Swift dictionaries (two copies at peak). Firebase, Amplitude and a GIF library (FLAnimatedImage, pulled in by `QazaqFoundation`) all load inside a keyboard capped at 🔎 roughly 48–70 MB. | `QazaqWordsDatasetLoader.swift:98-105`, `KeyboardViewController.swift:58-82` |
| 6 | ✅ **No release since about January 2025.** The upload is blocked until the app is built with Xcode 26. | `CONTEXT.md`, git log |

### High

- **No emoji keyboard.** Users must switch keyboards for every emoji, which is a top reason people abandon third-party keyboards. The setting is shown as "coming soon" (`SettingsView.swift:46-52`). KeyboardKit's emoji keyboard needs a paid Pro licence.
- **No tenge sign anywhere.** The currency key is `$`, and its long-press offers ₽ but not ₸ (`CyrillicService.swift:13`, `QazaqCalloutService.swift:52`).
- **Long-pressing "б" shows т / а / р / б**, a leftover joke ("брат" spelled backwards) at `QazaqCalloutService.swift:46`.
- **The Kazakh UI text has spelling mistakes, in a product about writing Kazakh correctly.** "узақ" should be **ұзақ**, "Саусағынызды" should be **Саусағыңызды**, "еңгізу" should be **енгізу** (keys `onboarding_alternative_chars_bullet_1..3`). The Russian text has "Отпустиить". The Kazakh welcome line "%@ қош келдіңіз" is missing the dative ending.
- **The Kazakh privacy-policy link goes to a generic freeprivacypolicy.com blog post**, not the app's policy (key `common_privacy_policy_content`, Kazakh version). The English and Russian versions link to termsfeed correctly.
- **Three names for one app.** It's "NeoQazaq" in the App Store and "Batyrma - Smart Qazaq Keyboard" on the home screen, where it gets cut off (`Qazaqsha/Info.plist:13`). Internally it's "Qazaqsha", and the GIF assets are called `selectNeoQazaqKeyboard*`. People can't recommend an app they can't name.
- **The main feature has been labelled "BETA" for about two years.** That tells users it's unreliable.
- **28 words in the Kazakh list contain Latin letters that look Cyrillic**, such as "aрқылы", "алy", "Iсмет". Suggesting them would slip Latin characters into users' Kazakh text and break search for whoever receives it.

### Medium

- **A 3-second fake loading screen at first launch**, the moment drop-off is highest (`OnboardingView.swift:35-41`).
- **The setup guide makes "Allow Full Access" a step** (`ManualKeyboardSetupView.swift:117`). Apple's rule 4.4.1 says a keyboard must "remain functional without full network access and without requiring full access". Make Full Access optional and explain what it adds (sounds and haptics need it).
- **The main screen has no keyboard status and no try-it field.** Users can't see whether the keyboard is enabled or has Full Access. The only try-it field is buried inside Magic Auto-Correction.
- **The review prompt fires when the app opens, every third launch or after 5 days** (`AppReviewService.swift:29-51`). It doesn't follow a good moment, and people rarely open the app after setup, so few ratings come in. `MainView.swift` also contains two dead copies of this logic.
- **Template leftovers in `Qazaqsha/Info.plist`:** photo-library and microphone permission texts (lines 7 and 9), the `kkdemo` URL scheme (line 34) and `INIntentsSupported` (line 40). These invite questions from Apple's review. The build number is hard-coded to `1` (line 39).
- **The welcome screen says no personal data is collected** (`data_not_collected`). Amplitude device IDs, Crashlytics, and contact details sent through the Telegram feedback form all count. The App Store privacy label and the privacy policy must match.
- **Analytics blind spot.** Without Full Access the keyboard has no network, so `launch_keyboard` only arrives from Full Access users. Keyboard metrics therefore describe a biased group. Nothing measures whether suggestions are accepted or undone.
- **Fragile hacks.** Keyboard-enabled detection reads the undocumented `AppleKeyboards` setting (`GlobalConstants.swift:16-22`). The iOS 18 troubleshooting tip checks `hasPrefix("18")`, so it never shows on iOS 26 or 27 (`NewKeyboardSetupView.swift:37`).

---

## 3. User pains, and what to build for each

| Pain | Evidence | What to build |
|---|---|---|
| Kazakh letters are slow, so people type with Russian letters and it looks illiterate | The app's core promise; 9 extra letters hidden behind long-press | Correction that never breaks correct words; an optional Kazakh-letter row or a key that toggles the last letter (к→қ, о→ө, у→ұ→ү) |
| iPhone has no Kazakh autocorrect or suggestions | 🔎 Apple's iOS 27 feature list | Word completion and next-word suggestions |
| Mixing Russian and Kazakh means switching keyboards mid-sentence | 🔎 ~49% of people use Kazakh daily; 52% mostly speak Russian at home; mixing is normal | One layout, both languages, language detected per word |
| Fear that the keyboard logs everything | 🔎 A competitor's review: "full access to everything… passwords" | Everything stays on the phone and works without Full Access, said loudly |
| Third-party keyboards miss basics | ✅ Emoji, ₸ and haptics are missing | Bring those up to par |
| Learners want to improve their Kazakh | The language-revival movement; many homes mostly speak Russian | Correct-spelling hints, an offline Kazakh–Russian dictionary, daily streaks (paid tier) |
| Professionals need formal Kazakh | ⚠️ Inferred | AI rewrite from Russian into Kazakh (paid, later) |

---

## 4. Plan: one keyboard for Kazakh and Russian

### 4.1 How Apple's multilingual typing works, and the Kazakh twist
- **Apple's version:** one layout with two language models running at once. Each word's language is guessed from its letters and the words around it. Suggestions and autocorrect come from whichever language fits.
- **The twist:** Kazakh is often typed **without its special letters**. A missing special letter must count as an almost-free correction. Apple doesn't handle that, and it's this product's advantage.

### 4.2 Architecture

```
each keystroke → current word + previous 2 words
 ├─ Language guess  how likely is this Kazakh? (letters + context)
 ├─ Candidates      completions (Kazakh with special letters stripped + Russian)
 │                  · typo fixes · Kazakh suffix generator for rare forms
 ├─ Ranking         context model + how close to what was typed + personal + language
 └─ Bar             ["as typed"] [best — auto-replace only if the rules allow] [alternative]
after space → next-word: top 3 from the context model, in the detected language
```

### 4.3 Components
- **Layout.** Keep one ЙЦУКЕН layout; it already holds all 33 Russian and 9 Kazakh letters. Add two options: a Kazakh-letter row, and a toggle key that cycles the last letter.
- **Language detection per word.**
  - Any of ә ғ қ ң ө ұ ү һ і means Kazakh.
  - щ, ё, ъ or э usually means Russian.
  - Otherwise, score letter patterns for each language and look at the previous words with a small two-state model. People rarely switch language in the middle of a phrase.
- **Dictionaries.**
  - Build them from real text, with frequencies: roughly 500k Kazakh word forms (Kazakh stacks suffixes, so there are many forms) and 300k Russian ones.
  - Also index Kazakh with special letters stripped (ә→а, қ→к, ң→н, ө→о, ұ/ү→у, ғ→г, һ→х, і→и/ы). Then "кан" completes to қандай and қанша, with Russian "как" offered alongside.
- **Typo fixes.** Allow one or two wrong letters, with neighbouring keys counting as cheaper mistakes. The existing suffix generator becomes the fallback for rare Kazakh forms. Extend it with the case endings and verb person endings it lacks today.
- **Next word.** A word-sequence model trained on mixed Kazakh and Russian text that predicts from the previous two words (a pruned trigram model). A small on-device neural model to re-rank (Core ML, 8-bit) can come later.
- **Ranking.** Combine four scores: how likely the word is in this context and language, how close it is to what was typed, a personal boost, and the language guess.
- **Auto-replace rules (this fixes critical issue 1).** Replace a word on space only if **all** of these hold:
  1. what was typed is not a real Kazakh or Russian word, or is far rarer than the candidate;
  2. the candidate wins by a clear margin;
  3. the user hasn't undone this same swap before.

  Backspace right after a correction restores the original and remembers the refusal. Truly ambiguous pairs (қол/көл, мен/мең) are decided by context or only suggested.
- **Personalisation.** Remember new words, the user's common word pairs (fading over time), and refused corrections. Pull contact names and iOS Text Replacements through `requestSupplementaryLexicon`.
- **Russian in the meantime.** iOS's built-in `UITextChecker` works offline for Russian (`ru_RU`). It can provide completions and spelling guesses before the new model ships.

### 4.4 KeyboardKit integration
- **`QazaqAutocompleteProvider.autocomplete(_:)`:**
  - Take the previous two words as context.
  - Return next-word suggestions when the current word is empty. Today it returns nothing (`:49`).
  - Mark only candidates that pass the rules as `.autocorrect`.
- **Learning and ignoring:** set `canIgnoreWords` and `canLearnWords` to `true`, and save their data in the personal store.
- **Undo:** subclass `KeyboardAction.StandardActionHandler` so that backspace right after an autocorrection restores the original word and calls `ignoreWord`.

### 4.5 Memory, privacy and Full Access
- **File format.** Ship the dictionaries and models as binary files mapped straight from disk (`Data(contentsOf:options: .alwaysMapped)`). Use sorted UTF-8 arrays or a compact word graph, integer word IDs and compressed probabilities. **Never** decode big JSON into dictionaries of Swift strings.
- **Budgets.** Under 35 MB of memory, and under 15 ms per keystroke for 95% of keystrokes on an iPhone 11-class phone. The keyboard limit is 🔎 roughly 48–70 MB, unofficial; measure it with Instruments.
- **What stays in the keyboard.** Remove Amplitude and FLAnimatedImage from it by splitting `QazaqFoundation` into a tiny core for the keyboard. Keep Crashlytics only if memory allows. No network calls from the keyboard.
- **Without Full Access** (🔎):
  - The keyboard can **read** the app's shared storage but cannot **write** to it.
  - Whether its own private storage is writable is unverified: test it on iOS 26 and 27, and make sure learning still works if it isn't.
  - Since iOS 26, opening URLs from the keyboard fails without Full Access.
- **Dictation** (🔎): keyboards cannot use the microphone. Any voice feature has to hop to the main app to record, as Wispr Flow does. That needs Full Access and microphone permission.

### 4.6 Data and licences
| Need | Source | Licence notes |
|---|---|---|
| Kazakh word frequencies | Kazakh Wikipedia | CC BY-SA. Use counts only. |
| Kazakh web text | CC-100, OSCAR, MADLAD-400 | Use statistics only; check each one's terms |
| Kazakh word forms | The Hunspell dictionary already in the repo (`Resources/DatasetConfig.playground/Resources/kk_KZ.txt`) | Get its affix file and expand every form with Hunspell's `unmunch` tool. Check the licence first. |
| Kazakh–Russian sentence pairs | ISSAI KazParC | Licence not confirmed |
| Russian | Russian Wikipedia, open word-frequency lists, Russian Hunspell dictionary | Check each licence |
| Mixed Kazakh–Russian text | Generate it from Kazakh–Russian sentence pairs, plus public social text where the terms allow | — |
| Mixed-language test set | KRCS (618 real mixed sentences) | **Testing only** |
| **Do not ship** | ISSAI KazLLM (CC-BY-NC, non-commercial); apertium-kaz (GPL-3) | Useful only as offline reference, after a licence review |

The data pipeline should also convert Latin look-alike letters to Cyrillic (a→а, i→і, y→у, o→о, e→е, c→с, p→р, x→х) and normalise all text to Unicode NFC.

### 4.7 Evaluation (every release must pass)
| Measure | Target |
|---|---|
| Wrong auto-replacements | ≤ 1 per 1,000 words typed |
| Keystrokes saved on chat-style text | ≥ 20–25% to start |
| Correct next word in the top 3 | Track release to release |
| Language detected correctly per word, on mixed text (KRCS) | ≥ 95% |
| Time per keystroke (95% of keystrokes) | < 15 ms on a low-memory phone |
| Memory | < 35 MB |

Simulate typing on held-out text in three styles: proper Kazakh, Kazakh with Russian letters only, and mixed Kazakh–Russian.

### 4.8 Roadmap (part-time, about 10–15 hours a week)
| Phase | Weeks | What ships |
|---|---|---|
| **0. Fixes** | 2 | Xcode 26 build. Never auto-replace real words (check the Kazakh and Russian lists first). Undo on backspace. Hide fragments that aren't words. ₸ sign. Fix the copy, the link and the "б" joke. Remove the fake loading screen and plist leftovers. Clean the Latin look-alikes. Add privacy-safe quality events. |
| **1. New engine** | 6–8 | Data pipeline, Kazakh dictionary with stripped-letter index, Russian dictionary, completion, typo fixes, language detection, new auto-replace rules, test suite → release "Қазақша + Русский" |
| **2. Prediction** | 6 | Next-word suggestions, personalisation, contact names and Text Replacements, two-language suggestion bar |
| **3. Basics + paid tier** | 6–8 | Emoji (KeyboardKit Pro licence, or a simple text grid you build), haptics, number row, Kazakh-letter row or toggle key, keyboard status on the main screen, paywall |
| **4. Later** | — | Neural re-ranking; swipe typing (🔎 Apple has none for Russian or Kazakh); Latin-alphabet Kazakh mode; AI features inside the main app |

---

## 5. Pricing and monetisation

### 5.1 Off the table
- **Selling "anonymous" data.**
  - Apple's rule 4.4.1 says keyboards must _"Collect user activity only to enhance the functionality of the user's keyboard extension on the iOS device."_
  - Typed text includes names, ИИН (national ID numbers) and card numbers. "Anonymised" text is not anonymous.
  - Kazakhstan's personal-data law requires consent, and UK GDPR likely applies if the business is run from London.
  - Trust is what a keyboard sells. A competitor's App Store reviews already show users worrying about keyloggers.
- **Ads inside the keyboard.** Apple's guidelines: _"Display advertising should be limited to your main app binary, and should not be included in extensions, App Clips, widgets, notifications, keyboards, watchOS apps, etc."_
- **Ads in the main app** are allowed but pointless, because people open it about once.

### 5.2 What people already pay (about 445₸ to the dollar)
| Item | Price |
|---|---|
| Yandex Plus (from October 5, 2026) | 2,499₸/month (annual reportedly 24,990₸, unconfirmed) |
| Competitor keyboard: AI dictation | 999₸/month · 9,990₸/year |
| Competitor keyboard: Kazakh–Russian dictionary / colour theme | 1,490₸ / 999₸, one-time |
| Average / median monthly salary (Q2 2026) | 486,388₸ / 348,415₸; real wages down 1.8% |
| Minimum wage (2026) | 85,000₸ |

### 5.3 Recommended tiers
Rule: **never charge for typing quality.** It drives growth, it's the mission, and the competitors are free.

| Tier | Price | What's in it |
|---|---|---|
| Free | 0 | Two-language suggestions and autocorrect, emoji, ₸, works offline |
| Plus | ≈1,990₸/year (~$4.50) | Kazakh ornament (ою-өрнек) themes, offline Kazakh–Russian dictionary in the keyboard, Latin↔Cyrillic mode, saved phrases, learning streaks |
| Plus Lifetime | ≈4,990₸ (~$11) | The same, forever. At launch, offer it at ~1,990₸ to the first N buyers as "founding supporters". |
| AI (later) | ~990₸/month or ~7,990₸/year | Rewrite Russian into proper Kazakh, formal letters. Dictation only via the main app, because keyboards can't use the microphone. |
| Tips | 990 / 2,990 / 9,990₸ | An opt-in supporters list. The unused "Donate" button is already in `MainView.swift:18-24`. |

- **What you keep:** after the 16% VAT and Apple's 15% cut (Small Business Program), about 73%. 1,990₸ becomes about 1,458₸ ($3.30); 4,990₸ becomes about 3,656₸ ($8.20).
- **Price points:** use the nearest real tenge points in App Store Connect. 999, 1,490 and 9,990₸ are confirmed to exist.
- **Test** with and without a monthly option. ⚠️ At low prices, yearly plus lifetime usually does better.

### 5.4 Reality check (⚠️ estimates)
- **Assumptions:**
  - Kazakhstan has about 21M people.
  - About 5M iPhone users (StatCounter's 41–47% is a share of web traffic, which overstates the share of devices).
  - About 2.5–3M of them type Kazakh.
  - The keyboard reaches 100–300k monthly users within about 2 years.
  - 3–4% of them pay.
- **Result:** 100k users × 3% × $3.30 ≈ **$10k a year**. 300k users × 4% × $3.30 ≈ **$40k a year**. That's good side income, not a company.
- **Comparison point:** the leading competitor has about 3K ratings in the Kazakhstan store. ⚠️ If 1–2% of users leave a rating, that's roughly 150k–300k installs over its lifetime.

### 5.5 Bigger opportunities
1. **License the engine to businesses.** Banks, marketplaces, telecoms and government services need it for search boxes and support bots: fixing sloppy spelling, spell-check, Latin↔Cyrillic conversion. Their search loses results when "казак" doesn't match "қазақ".
2. **Sponsors instead of ads.** For example, "Plus free for students and teachers, supported by [company]", shown in the app, never in the keyboard.
3. **Grants.**
   - QazaqCreative LitTech: 10 grants of 5M₸. The 2026 round closed on September 28; watch for the next one.
   - "Тәуелсіздік ұрпақтары": for Kazakh citizens aged 14–34. The 2026 round closed on June 21.
   - Astana Hub programmes.
4. **Other languages Apple skips.** 🔎 Apple's predictive-text list also lacks Kyrgyz, Uzbek, Tajik, Azerbaijani, Turkmen, Mongolian, Georgian, Armenian and Belarusian. The same engine, especially for the Turkic languages, multiplies the market.
5. **Android.** Android is 🔎 about 53–59% of Kazakhstan's mobile web traffic. Check how well Gboard handles Kazakh before investing.

---

## 6. Marketing plan

### 6.1 Name
**Pick one name.** The recommendation is **Batyrma**:
- "батырма" means "button/key" in Kazakh, so it's a real word, short and ownable;
- it's already the name on the home screen.

Rename the App Store listing to "Batyrma — қазақша пернетақта" and put Russian keywords in the subtitle (казахская клавиатура, автозамена). The ratings stay because the app ID doesn't change. NeoQazaq would also work; what matters is using one name everywhere.

### 6.2 Positioning
- "Шала жазсаң да, таза шығады." ("Even if you type it sloppy, it comes out correct.")
- "Қазақша да, орысша да, бір пернетақтада." ("Kazakh and Russian, in one keyboard.")
- Proof point: Apple's own iOS 27 list shows no Kazakh autocorrect or predictive text on iPhone.
- Privacy line: "Works offline. Your typing never leaves your phone."

### 6.3 Founder story
"A Kazakh engineer in London built the keyboard Apple never made for Kazakh."

⚠️ Before naming Meta, check the employment contract and the employer's rules on outside projects and IP ownership. Use the company name only with written approval.

### 6.4 Content
Short videos for Threads, Instagram Reels (🔎 about 13.6M Instagram users in Kazakhstan) and TikTok:
- A race: the iPhone keyboard against Batyrma, typing "Қалайсың, қалың қалай?"
- A close-up of sloppy input turning into correct Kazakh.
- "Сәлем, как дела? Ертең кездесеміз бе?" typed with no keyboard switching.
- Funny cases of the Russian keyboard mangling Kazakh words (ask followers to send theirs).
- Weekly behind-the-scenes posts about building it.

### 6.5 Built-in sharing
- A share card in the app ("Мен қазақша таза жазамын", "I write proper Kazakh").
- Invite 3 friends, get 3 months of Plus.
- A community "add a missing word" feature that credits contributors.
- Streaks calculated only on the phone.
- **Never** add "sent with Batyrma" to messages, and never use typed text for marketing (rule 4.4.1).

### 6.6 Partners and channels
- **Creators and schools:** Kazakh-language creators; teachers, who can spread it to students and parents.
- **Universities:** clubs at NU, KBTU and SDU. SDU has published a thesis on Kazakh word prediction for iOS, so it's also a source of research partners and interns.
- **Ecosystem:** Astana Hub, and Language Policy Committee events around September 5.
- **Media:** Tengrinews, Kursiv, Digital Business, The Steppe, Forbes Kazakhstan.
- **Professional and tech audiences:** Kazakh professionals abroad on LinkedIn; a technical write-up on Habr or VC.ru ("How I built an on-device Kazakh keyboard").

### 6.7 Paid
- Apple Search Ads (🔎 Kazakhstan was included from 2019; confirm in the console) on terms like "казахская клавиатура" and "қазақша пернетақта".
- A small budget for demo videos on Reels and Threads.
- Compare the cost per install against organic installs.

### 6.8 Calendar
| When | What |
|---|---|
| December 2026 | Release the Phase 0 fixes and the rename; post on Independence Day, December 16 |
| January–March 2027 | Test version with 300–1,000 users recruited on Threads and Telegram, building in public |
| **March 21–23, 2027 (Nauryz)** | Public relaunch, "Жаңа жыл, жаңа пернетақта" ("New year, new keyboard"), founding-supporter deal, press and creators |
| **September 1–5, 2027** | Back to school plus Language Day, Baitursynov's birthday: "He gave us the letters; we made them easy to type." Teacher programme |

### 6.9 Numbers to track
- Installs → keyboard enabled → first use → still using at days 1, 7 and 30.
- Suggestions accepted per 100 words.
- Corrections undone (target under 2%).
- Kazakh/Russian word share (counts only).
- Share rate.
- Paid conversion.

---

## 7. Analytics (Amplitude)

### 7.1 Events tracked today
| Event | Where it fires |
|---|---|
| `app_start` | App launch |
| `onboarding_welcome`, `onboarding_alternative_char_long_press`, `onboarding_keyboard_setup`, `onboarding_magic_autocorrection`, `onboarding_finish` | Each onboarding page |
| `launch_keyboard` | Each time the keyboard loads (`viewDidLoad`), with `isAutocompleteEnabled`, `isAutoCapitalizationEnabled` and `isKeyClicksSoundEnabled`. Only sent if Full Access is on. |

### 7.2 Charts to pull now
1. **The onboarding funnel:** `app_start` → each `onboarding_*` page → `onboarding_finish` → first `launch_keyboard`. This shows where installs drop off.
2. **Share of `launch_keyboard` users with `isAutocompleteEnabled = false`.** This measures directly how many people switched off the main feature, probably because of critical issue 1.
3. **Share of installs that ever send `launch_keyboard`.** That's the Full Access share, so it tells you which group the 50% day-14 retention actually describes.
4. **Retention at days 1, 7, 14 and 30** on `launch_keyboard`, split by app version.

### 7.3 Events to add (counts only, never typed text)
- **Setup steps:** Settings opened, keyboard enabled detected, Full Access status, first keyboard session.
- **A once-a-day keyboard summary:** bucketed number of words typed; suggestions shown and accepted; corrections applied and undone; bucketed Kazakh/Russian share. This only works with Full Access, because the keyboard has no network without it.
- **Money:** paywall viewed, purchase started, purchase completed.

---

## 8. Next two weeks
1. **Phase 0 fixes**, plus the regression test in Appendix C.
2. **Install Xcode 26 and ship.** The steps are already in `CONTEXT.md`.
3. **Rename everything to one brand** and redo the App Store screenshots to lead with the before/after.
4. **Pull the four Amplitude charts** in section 7.2.
5. **Check the employment and IP question** before using the founder story publicly.
6. **Choose the tenge price points** in App Store Connect and decide whether to offer a monthly plan.

**Decisions to make:** the brand name; Full Access optional or not; the price tiers; whether to name the employer in the founder story.

---

## Appendix A: Engine test results (real code, 2026-11-23)

These results come from compiling the real engine sources and mirroring the logic of `QazaqAutocompleteProvider`: candidates sorted by score, up to 2 shown, autocorrect if the score is above 0.95.

**Correct Kazakh words typed as-is**
| Typed | Suggestions (score) | After space |
|---|---|---|
| ол | өл (1.00) | ⚠️ becomes **өл** |
| бар | бәр (1.00) | ⚠️ becomes **бәр** |
| сол | сөл (1.00) | ⚠️ becomes **сөл** |
| сен | сең (1.00) | ⚠️ becomes **сең** |
| болу | бөлу (1.00) | ⚠️ becomes **бөлу** |
| онда | оңда (1.00) | ⚠️ becomes **оңда** |
| ма | мә (1.00) | ⚠️ becomes **мә** |
| ай | әй (1.00) | ⚠️ becomes **әй** |
| нан | нән (1.00) | ⚠️ becomes **нән** |
| сал | сәл (1.00) | ⚠️ becomes **сәл** |
| барамын | барамың (1.00) | ⚠️ becomes **барамың** (not a word) |
| мен | мең (0.90) | stays (suggestion only) |
| олар, болды, жазу, рахмет, сабақ, қазақ | none | stays |

**Kazakh typed with Russian letters (the intended use)**
| Typed | Suggestions (score) | After space |
|---|---|---|
| салем | сәлем (1.00) | ✓ сәлем |
| кандай | қандай (1.00) | ✓ қандай |
| калайсын | қалайсың (1.00) | ✓ қалайсың |
| жаксы | жақсы (1.00) | ✓ жақсы |
| бугин | бүгін (1.00) | ✓ бүгін |
| ертен | ертең (1.00) | ✓ ертең |
| казагым | қазағым (0.95) | stays: 0.95 isn't above the 0.95 threshold, so this *correct* fix is never applied |

**Russian words**
| Typed | Suggestions (score) | After space |
|---|---|---|
| кит | қит (1.00) | ⚠️ becomes **қит** |
| как | қақ (0.90) | stays (suggestion only) |
| привет, спасибо, хорошо, сегодня, нормально, давай, пока, когда, она, кто, все, это, только, тоже, завтра, работа, мама, сейчас, дела | none | stays, with no help at all |

**Partial words while typing (what the bar shows)**
| Typed so far | Bar shows |
|---|---|
| ка | қа, кә (0.90) |
| кан | кән, қан (0.90) |
| канд | кәнд, қанд (0.90) |
| кал | кәл, қал (0.90) |
| бол | бөл (0.90) |
| мек / мектеп / мектепке | none |
| рах | none |
| китапта | кітапта (0.90) |
| казакстан | қазақстан (1.00) |
| азамат, алматы | none |

**Dataset scan**
- **Map entries:** 36,895. Of these, 36,576 score 1.0, 622 score 0.9 and 6 score 0.95. Only 9 entries list the typed word itself as an option.
- **Affected words:** 311 entries are real words from the 54k Kazakh list that map to a *different* word at ≥ 0.95, so they are replaced on space.
- **Latin look-alikes:** 28 entries in the Kazakh list contain Latin letters.
- **Russian list:** 1,982 lines with Windows line endings. It loads correctly in Swift; the line-splitting is fine. It contains duplicate blocks and junk entries.

**Why it happens**
- `findVariations` (`WordSuggestionsEngine.swift:68-79`) checks the map first and the "already a Kazakh word" list only third.
- The provider marks anything above 0.95 as `.autocorrect` (`QazaqAutocompleteProvider.swift:62`).
- KeyboardKit 9.0.8's `StandardActionHandler.tryApplyAutocorrectSuggestion` applies the first such suggestion when space or punctuation is released. The provider's `ignoreWord` does nothing, so there's no way out.

**Test harness:** `/private/tmp/claude-501/-Users-daukabase-NeoQazaq/5d87423a-60a3-43f0-8a3e-eb3e2a3a4d35/scratchpad/engine`. It's a temporary folder and may be cleared. To rebuild it:
1. Copy the `Core Layer` and `QazaqEndingsGenerator` Swift files plus `QazaqFoundation/Extensions/Swift/String+.swift` into one folder.
2. Delete the `import QazaqFoundation` lines.
3. Copy the `Recources` data files next to the binary.
4. Add a `main.swift` that loads the data, waits about 3 seconds, and calls `QazaqWordSuggestionsEngineV2().suggestWords(for:)`.
5. Build with `swiftc -swift-version 5 -O`.

---

## Appendix B: Market and competitor data

**Apple iOS 27 keyboard features (🔎 apple.com/ios/feature-availability)**
| Feature | Kazakh | Russian |
|---|---|---|
| Keyboard layout | ✅ | ✅ |
| Predictive text (QuickType) | ❌ | ✅ |
| Auto-correction | ❌ | ✅ |
| Multilingual typing | ❌ | ❌ |
| Dictation | ❌ | ✅ |
| Inline predictive text | ❌ | ❌ |
| Swipe typing (QuickPath) | ❌ | ❌ |

**Competitors in the Kazakhstan App Store (🔎)**
| App | Rating | Money | Notes |
|---|---|---|---|
| Kazakh Keyboard Qazaq Keyboard | 4.3★, about 3K ratings | Colour keyboard 999₸; Kazakh–Russian dictionary 1,490₸; AI dictation 999₸/month or 9,990₸/year; booster 999₸ | Version 3.1 (November 28, 2025) added Kazakh voice typing. A review calls the Full Access request "suspicious". |
| Perne | 3.7★, 3 ratings | Free | "Keyboard with autocorrect" |
| KazKey | — | Free | The listing says autocorrect, suggestions and emoji are planned |
| Kiwi keyboard, Qazaq Latyn Keyboard 2021 | — | — | Basic layouts, Latin alphabet |

**Kazakhstan market (🔎)**
| Metric | Value |
|---|---|
| Social-media users (October 2026) | 18.3M, 86.6% of the population (so about 21.1M people) |
| Instagram users | ~13.6M (NapoleonCat, 2026) |
| iOS share of mobile web traffic | ~41–47% (StatCounter, May–August 2026; a traffic share, not a device share) |
| Speak Kazakh / Russian (2021 census) | 80.1% / 83.7% |
| Use Kazakh daily | 49.3% of everyone; 63.45% of ethnic Kazakhs |
| Language used most at home (CA-Barometer) | Russian 52%, Kazakh 44% (Astana: 64% Kazakh; Kostanay: 12% Kazakh) |
| Dollar exchange rate (November 9–14, 2026) | 443.6–449.0₸ |
| VAT | 16% from January 1, 2026 (up from 12%) |
| Language Day | September 5, Akhmet Baitursynov's birthday (since 2018) |

---

## Appendix C: Regression test to add

Add this to `WordSuggestionsEngine/WordSuggestionsEngineTests/QazaqWordSuggestionsEngineTests.swift`. It fails today, and it must pass after the Phase 0 fix:

```swift
func test_validWordsAreNeverAutoReplaced() {
    // Correct, frequent Kazakh words must never get a high-confidence (> 0.95)
    // replacement, because the provider auto-applies those on space.
    let validWords = ["ол", "бар", "сол", "сен", "болу", "онда", "ма", "ай", "нан", "сал", "барамын"]
    for word in validWords {
        let replacement = engine.suggestWords(for: word).first { $0.similarity > 0.95 }
        XCTAssertNil(replacement, "\(word) would be auto-replaced with \(replacement?.word ?? "")")
    }
}
```

Also add a Russian case (for example "кит") once Russian words are checked against a Russian dictionary.

---

## Sources
- [Apple: iOS 27 feature availability](https://www.apple.com/ios/feature-availability/)
- [Apple App Review Guidelines (4.4.1 keyboards, advertising, 3.1.2 subscriptions)](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Developer Forums: request for autocorrect in Kazakh and other Cyrillic languages](https://developer.apple.com/forums/thread/833277)
- [Apple: configuring open access for a custom keyboard](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard)
- [Competitor: Kazakh Keyboard Qazaq Keyboard](https://apps.apple.com/kz/app/id945362470)
- [Perne](https://apps.apple.com/kz/app/perne/id6449842400)
- [KazKey](https://apps.apple.com/us/app/kazkey-%D0%BA%D0%B0%D0%B7%D0%B0%D1%85%D1%81%D0%BA%D0%B0%D1%8F-%D0%BA%D0%BB%D0%B0%D0%B2%D0%B8%D0%B0%D1%82%D1%83%D1%80%D0%B0/id1320863689?l=ru)
- [SDU thesis on Kazakh word prediction for iOS](https://repository.sdu.edu.kz/handle/123456789/1574)
- [StatCounter: Kazakhstan mobile OS share](https://gs.statcounter.com/os-market-share/mobile/kazakhstan)
- [Yandex Plus price in Kazakhstan](https://finratings.kz/news/17381-iandeks-otkazalsia-peresmatrivat-tsenu-podpiski-v-kazakhstane-posle-masshtabnykh-sboev/)
- [Bureau of National Statistics: wages](https://stat.gov.kz/ru/news/zarabotnaya-plata-za-i-kvartal-2026-goda/)
- [Real wages fell (RFE/RL)](https://docs.rferl.org/ru-kz/2026/09/02/pdf/33845418/e555cd168b194f08a9ad3c0438d72adf.pdf)
- [Tenge exchange rate, November 2026](https://bank.kz/news/finansy-news/kursy-valyut-14-noyabrya-2026/)
- [16% VAT from 2026](https://digitalbusiness.kz/2025-12-25/nds-16-s-2026-goda-kto-platit-i-chto-budem-brat-v-zachet/)
- [DataReportal: Digital 2027 Kazakhstan](https://datareportal.com/reports/digital-2027-kazakhstan)
- [NapoleonCat: social media users in Kazakhstan](https://napoleoncat.com/stats/social-media-users-in-kazakhstan/)
- [Languages of Kazakhstan](https://en.wikipedia.org/wiki/Languages_of_Kazakhstan)
- [CA-Barometer: what language Kazakhs speak at home](https://ca-barometer.org/en/publications/what-language-do-the-kazakhs-speak-at-home)
- [Language Day, September 5](https://www.nur.kz/leisure/holidays/1618076-den-azykov-naroda-kazahstana-data-istoria-prazdnika/)
- [QazaqCreative LitTech grants](https://digitalbusiness.kz/2026-08-19/50-mln-tenge-gotovi-otdat-kazahstanskim-startapam-kotorie-izmenyat-literaturu-i-chtenie/)
- [Тәуелсіздік ұрпақтары grant](https://www.gov.kz/memleket/entities/fam/press/news/details/1205746?lang=ru)
- [ISSAI KazLLM release and licence](https://issai.nu.edu.kz/2024/12/10/official-release-of-the-issai-kaz-llm-open-source-model-is-available/)
- [KazParC](https://huggingface.co/datasets/issai/kazparc)
- [KRCS mixed Kazakh–Russian dataset](https://arxiv.org/html/2503.20007v1)
- [apertium-kaz](https://github.com/apertium/apertium-kaz)
- [Keyboard extension memory limit (React Native docs)](https://reactnative.dev/docs/app-extensions)
- [Keyboard dictation by hopping to the app (Wispr Flow)](https://docs.wisprflow.ai/articles/7453988911-Set-up-the-Flow-keyboard-on-iPhone)
- [Apple Search Ads expansion including Kazakhstan (2019)](https://9to5mac.com/2019/03/27/app-store-search-ads-rolls-out-to-46-more-countries/)
