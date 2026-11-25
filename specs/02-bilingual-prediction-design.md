# Bilingual Kazakh + Russian predictive keyboard: system design

_Date: 2026-11-23 · Status: v1 of completion and next-word prediction implemented 2026-11-24 (Wikipedia counts; see CONTEXT.md §5). Not yet done: typo correction, language detection beyond letters, personal word counts, chat-style data._
_Related: [`01-fix-spec.md`](01-fix-spec.md) (stopgaps that ship first) · [`../PRODUCT_STRATEGY.md`](../PRODUCT_STRATEGY.md)_

## 0. Summary

**What we build.**
- One ЙЦУКЕН keyboard where people type proper Kazakh, Kazakh with only Russian letters ("shala"), Russian, or a mix, without switching keyboards.
- It restores Kazakh letters when that's safe, completes words, predicts the next word, fixes typos, learns the user's words, and never "fixes" a correct word.
- Everything runs on the phone, offline, without Full Access.

**How.**
- **Data:** big word lists with frequencies, for Kazakh and for Russian.
- **Two error models:** a "shala" model, where a missing Kazakh letter is nearly free, and a typo model based on neighbouring keys.
- **Prediction:** a model that predicts the next word from the previous two words (a pruned word n-gram model).
- **Language detection:** a cheap per-word guess built from letters, the dictionaries and context.
- **Strict autocorrect rules.**
- **Format:** all data lives in sorted files mapped straight from disk, and a Swift engine reads them. The engine doesn't depend on KeyboardKit and also runs on macOS, which allows offline evaluation with release gates.

**Why it will work.**
- **Proven architecture.** Production keyboards used it before neural models: Google's Gboard decoder combines a dictionary, a touch model and an n-gram model. Google also handles keyboards where the typed letters differ from the output script, which is the same problem as shala typing.
- **It fits the memory budget.** The memory-mapped approach was measured at **0.18 µs per lookup and 2.7 MB peak memory**, versus 37.4 MB for today's loader.
- **Simple to build.** It needs no GPU, no server and no training infrastructure, and every piece can be unit-tested.
- **Room to grow.** A small neural re-ranker can be added later.

---

## 1. How Apple (and Google) do it

### 1.1 Apple multilingual typing (what the user sees)
- **Setup:** you add 2–3 keyboard languages. QuickType then lets you type in any of them without switching manually.
- **Suggestions:** they cover all the languages. The first suggestion follows your language priority, and the keyboard picks up the language you're typing. ([iPhone User Guide](https://support.apple.com/en-asia/guide/iphone/use-predictive-text-iphd4ea90231/15.0/ios); [3 languages since iOS 18](https://www.idownloadblog.com/2017/01/16/how-to-multilingual-typing-iphone/))
- **Gap:** **neither Kazakh nor Russian** is supported for multilingual typing in iOS 27. Kazakh also has no predictive text, autocorrect, dictation or swipe at all. ([Apple feature availability](https://www.apple.com/ios/feature-availability/))

### 1.2 How Apple detects the language
From [Apple Machine Learning Research, "Language Identification from Very Short Strings" (2019)](https://machinelearning.apple.com/research/language-identification-from-very-short-strings):
- **Purpose:** language detection is needed _"to load the right autocorrection lexicon and the right language model for predictive and multilingual typing."_
- **Why it's hard:** _"strings composed of a few characters are often present in more than one language."_ Typical input is 10–50 characters long.
- **Model:**
  - Detecting the script (Latin, Cyrillic…) comes first and is cheap. Then each script gets its own network, because mixing scripts _"resulted in higher confusability."_
  - The network is a **two-layer bidirectional LSTM over characters** (about 250 characters), with a softmax at each character. _"A max pooling style majority voting decides the dominant language."_
- **Training:** sequences start at the beginning of a word. Nothing improved beyond 50 characters. Evaluation used 10-character strings (1–2 words).
- **Results:** **15–60% fewer errors** and **40–80% smaller** than the previous n-gram models. The model is 4 MB on iOS, against 7 MB before.

### 1.3 Apple prediction and autocorrect (iOS 17 and later)
- **Model:** an **on-device transformer language model** runs on every keypress and is personalised on the phone ([9to5Mac](https://9to5mac.com/2023/06/05/ios-17-iphone-autocorrect/)).
- **Size:** reverse engineering found a GPT-2-style model with **6 decoder blocks, hidden size 512, about 34M parameters, and a 15k-token vocabulary**. It lives in a per-language bundle (`…/en.lm/unilm.bundle`) and _"mostly completes individual words"_ ([Jack Cook](https://jackcook.com/2023/09/08/predictive-text.html)).
- **Undo:** corrections are underlined briefly, and tapping one reveals the original word. The keyboard learns words you keep using.
- **Why we can't copy it:** Apple's keyboard is part of the system and has no extension memory cap. A third-party keyboard gets roughly 48–70 MB in total, so a 34M-parameter model (34–70 MB) is out of reach. Our realistic ceiling for a neural model is about 2–5 MB with 8-bit weights.

### 1.4 How Apple learns new words
- It uses **local differential privacy**, and only with opt-in. It discovers new and trending words (e.g. "wyd", "bruh") and emoji habits to update the on-device dictionaries, without collecting raw text ([Apple ML Research](https://machinelearning.apple.com/research/learning-with-privacy-at-scale)).
- **We skip this in v1.** It needs a server, and Apple's rule 4.4.1 limits keyboard data use to improving the keyboard on the device.

### 1.5 Google Gboard: the public blueprint
- **Decoder:** built from **weighted finite-state transducers**, a way of chaining a touch model, a dictionary and an n-gram model. One framework handles literal input, autocorrect, completion and next-word prediction under tight memory and speed limits ([Ouyang et al., 2017](https://arxiv.org/abs/1704.03987)).
- **Transliterated keyboards:** for languages where the typed letters differ from the output script, Gboard uses the same machinery; it launched for 22 languages in 2017 ([Hellsten et al.](https://research.google/pubs/transliterated-mobile-keyboard-input-via-weighted-finite-state-transducers/)). **Shala Kazakh is exactly this problem:** the user types a reduced alphabet and we output the full one.

### 1.6 What we copy and what we change
| Apple / Google | Our v1 | Why |
|---|---|---|
| Script detection, then a neural language detector per script | One script (Cyrillic). Kazakh-only letters give certainty for free. Otherwise: letter-pattern scoring + dictionary evidence + a small context model across words. | Two languages, one script, tiny and explainable. Switch to a small char-LSTM ([Apple's recipe](https://machinelearning.apple.com/research/language-identification-from-very-short-strings)) only if accuracy is under 95%. |
| Transformer LM per language | Pruned word n-gram model over mixed Kazakh/Russian text; optional neural re-ranker later | Fits the memory cap; little Kazakh data; one developer |
| Dictionary + touch model + n-gram (Gboard) | Dictionary search + typo model based on neighbouring keys + n-gram | Same idea, without a transducer toolkit |
| Transliteration transducer | The **shala model**: a "stripped letters" index where restoring a Kazakh letter costs about 0 | Shala is a deterministic many-to-one mapping |
| Tap an underlined word to revert | **Backspace right after a correction reverts it**, records the refusal, and learns the word | A keyboard can't see taps inside the host app's text, so backspace is the equivalent |
| Differential-privacy word discovery | No (v1). On-device learning only. | Privacy and Apple rule 4.4.1 |

---

## 2. Requirements

| ID | Requirement |
|---|---|
| F1 | Type proper Kazakh, shala Kazakh, Russian, and mixed text, with no switching |
| F2 | Restore Kazakh letters automatically when it's unambiguous |
| F3 | Complete words from the 2nd letter |
| F4 | Predict the next word after a space |
| F5 | Fix typos: neighbouring keys, a missing or extra letter, swapped letters |
| F6 | Never replace a correct word; undo with backspace; learn the user's words |
| F7 | Three-slot suggestion bar that can show the other language when it's unclear |
| N1 | Offline; works without Full Access; no typed text ever leaves the phone |
| N2 | Whole keyboard under 30–35 MB of memory; engine's own heap memory under 10 MB |
| N3 | Under 15 ms per keystroke for 95% of keystrokes on an iPhone 11-class phone (engine alone under 5 ms) |
| N4 | At most 1 wrong auto-replacement per 1,000 words; at least 20–25% of keystrokes saved on chat text |
| N5 | Model files add at most 40 MB to the app |

---

## 3. What users type

| Style | Example typed | Expected result |
|---|---|---|
| Proper Kazakh | қандай | completes or keeps as typed |
| Shala Kazakh (no Kazakh letters) | кандай, калайсын, кездесемиз | қандай, қалайсың, кездесеміз |
| Russian | привет, как дела | keep; complete and predict in Russian |
| Mixed in one sentence | Сәлем, как дела? ертен кездесемиз бе | Сәлем, как дела? ертең кездесеміз бе |
| Typos | калвйсын (в next to а) | қалайсың |

**Stripping Kazakh letters (`fold`), used only for searching:**
- ә→а, ғ→г, қ→к, ң→н, ө→о, ұ→у, ү→у, һ→х, ё→е.
- **і** gets indexed twice, once as **и** and once as **ы**, because shala typists use both (бір → "бир" and "быр"). A word with *k* і's gets 2^k index entries; *k* is almost always 2 or less.
- Search uses the stripped form. Ranking uses the exact error costs (section 6.3).

**Case and tokens.**
- Searching ignores case, and the user's capitalisation is put back afterwards (the existing helper).
- Word characters are Cyrillic letters, hyphens and apostrophes.
- No autocorrect when the word contains digits, starts with `@` or `#`, comes right after `/` or `:`, or the text field is a URL, email or password field.

---

## 4. Architecture

```
            ┌──────────────────────── Batyrma (keyboard extension) ────────────────────────┐
 keystroke →│ KeyboardKit ─► QazaqActionHandler (undo/learn, see fix spec C2)              │
            │      │                                                                        │
            │      ▼  autocompleteText = documentContextBeforeInput                         │
            │ KeyboardAdapter: tokenize → InputContext(prev2, prev1, partial, sentenceStart)│
            │      │                                                                        │
            │      ▼                                                                        │
            │ ┌──────────────── PredictionEngine (Swift package, Foundation only) ────────┐ │
            │ │ LanguageID ─► CandidateGenerator ─► Scorer ─► AutocorrectPolicy ─► Bar      │ │
            │ │     ▲               ▲                 ▲              ▲                     │ │
            │ │  lid.bin     kk.words/kk.fold    ngram.bin     PersonalStore               │ │
            │ │              ru.words/ru.fold    (+vocab)      (learned, rejected, bigrams)│ │
            │ │              prefix.top     all memory-mapped, read in place               │ │
            │ └─────────────────────────────────────────────────────────────────────────────┘ │
            └────────────────────────────────────────────────────────────────────────────────┘
 offline:  tools/pipeline (Python) ──► the data files + manifest.json ──► tools/eval (Swift CLI on macOS)
```

**Modules.**
- **`PredictionEngine`:** a new Swift package with no UIKit or KeyboardKit dependency, so it builds on iOS and macOS. Public entry point: `func suggest(_ ctx: InputContext) -> SuggestionResult`, synchronous, at most 5 ms.
- **`KeyboardAdapter`** (in the Batyrma target):
  - Turns KeyboardKit's text into an `InputContext`.
  - Maps the result to `Autocomplete.Suggestion`s.
  - Runs requests on one background queue with a request token, so stale results are dropped. KeyboardKit's `autocomplete(_:updating:)` starts a new `Task` per keystroke, and an older answer could otherwise overwrite a newer one.
- **`tools/pipeline`:** offline Python that builds every data file from the corpora (section 7).
- **`tools/eval`:** a Swift command-line tool that links `PredictionEngine` and replays typing over test sets (section 8). It's the same code as on the phone, so results match.

---

## 5. Data files on the phone

| File | What's in it | Format | Size (estimate) |
|---|---|---|---|
| `kk.words` + `.idx` | 300–500k Kazakh word forms; line number = word ID | sorted UTF-8 lines `word\tq\tflags`, where q = log-frequency squeezed into 0–255 | 8–10 MB |
| `kk.fold` + `.idx` | stripped key → word IDs, most frequent first | sorted lines `key\tid,id,…` | 6–8 MB |
| `ru.words` / `ru.fold` + `.idx` | 200–300k Russian word forms (ё stripped to е) | same | 5–6 MB |
| `prefix.top` + `.idx` | top 8 completions for every stripped prefix of 1–3 letters | lines `prefix\tlang:id,…` | under 1 MB |
| `vocab.map` | joint Kazakh/Russian vocabulary for the n-gram model → word IDs in each language | binary array | about 2 MB |
| `ngram.bin` | ~300k two-word and ~300k three-word contexts → top 5 next words | fixed-size records sorted by 64-bit context hash: `hash:UInt64, 5×(id:UInt32, q:UInt8)` = 33 bytes | 15–20 MB |
| `lid.bin` | letter-triple probabilities: Kazakh (proper + stripped text) and Russian | 2 × 43³ one-byte values | about 160 KB |
| `flags` | per word: `suggestOnly` (profanity, the "0.95" entries), `properNoun`, `protected` | bits inside the `*.words` lines | — |
| `allowlist.txt`, `blocklist.txt` | reviewed exceptions (from `data/autocorrect-conflicts.tsv`) | one word per line | tiny |
| `manifest.json` | format version, counts, checksums, list of sources | JSON | tiny |

- **Every file is mapped from disk** with `Data(contentsOf:options: .alwaysMapped)`, and line positions come from prebuilt `.idx` files of `UInt32` offsets, also mapped. So there's **no parsing and almost no heap memory**. Mapped pages are clean memory: iOS can drop them under pressure.
- **Lookups are binary searches.** Prefix searches take the range `[lowerBound(p), lowerBound(p + "\u{10FFFF}"))`.
- **Prototype measured at 0.18 µs per lookup** (`/private/tmp/claude-501/-Users-daukabase-NeoQazaq/5d87423a-60a3-43f0-8a3e-eb3e2a3a4d35/scratchpad/mmapproto/main.swift`, a temporary folder).
- **Version safety:** the engine checks `manifest.json` and turns prediction off if the format version doesn't match. The keyboard stays usable.

---

## 6. Algorithms

### 6.1 Language detection, per word and per sentence
For the current word `t`, compute how much more likely Kazakh is than Russian (log-odds `L`):
1. **Letters:**
   - Any of ә ғ қ ң ө ұ ү һ і means **Kazakh, certain** (P ≈ 0.999). Stop here.
   - Any of ё ъ э щ adds **−3** (strong Russian evidence, but not certain, because Kazakh text contains Russian loanwords).
2. **Dictionaries:** `L_dict = clip(log f_kk(t) − log f_ru(t), ±3)`.
   - `f_kk` includes **stripped-form hits**, so a shala word counts as Kazakh evidence.
   - Words in both lists (телефон, мама) add about 0.
3. **Letter patterns:** `L_char` = average over letter triples of `log P_kk − log P_ru`. P_kk is trained on proper **and** stripped Kazakh text, so shala text looks Kazakh too.
4. **Context:** a two-state model (Kazakh/Russian) over the sentence. Staying in the same language has probability 0.9 (tune this on mixed text). The previous words' result is the prior.

Combined: `logit P_kk(t) = 1.0·L_dict + 0.5·L_char + letter evidence + log(prior_kk / prior_ru)`. The weights are a starting point; tune them on the evaluation sets.

The output is `P_kk` for the current word, plus a sentence language used for next-word prediction. If accuracy on mixed test text is under 95%, train a tiny char-LSTM in Core ML (under 1 MB) following Apple's recipe: one script, sequences starting at a word boundary, lengths 1–50.

### 6.2 Finding candidates (at most 50 per keystroke)
1. **Completions:** the stripped-prefix range in `kk.fold` and `ru.fold`. Use `prefix.top` for prefixes of 3 letters or fewer. For longer prefixes, scan the range (capped at 2,000) and keep the top K by frequency.
2. **Exact and shala matches:** look up `fold(typed)` exactly in `kk.fold`, and the typed word in `ru.words`.
3. **Typos** (words of 3+ letters): generate single edits of `fold(typed)` and look each one up:
   - removed letters;
   - **swaps with neighbouring keys only** (about 5 neighbours each on ЙЦУКЕН);
   - swapped adjacent letters;
   - inserted neighbouring letters.

   That's at most ~150 lookups, about 30 µs. It needs no memory, unlike a precomputed "deletion" index.
4. **Kazakh word endings:** if nothing is found and P_kk > 0.5, fall back to the existing `QazaqEndingsGenerator` (dictionary root + generated ending). Extend it later with case endings and verb person endings.
5. **The user's own words:** learned words that match the prefix (from `PersonalStore`).

### 6.3 Ranking
```
score(w) = log10 P_LM(w | prev2, prev1)     // n-gram with fallback; just word frequency in Phase 1
         + C(typed → w)                     // error cost
         + log10 P_LID(lang(w))             // from 6.1
         + U(w)                             // personal boost
```
| Term | Starting value (log10) |
|---|---|
| Exact letter match | 0 |
| Each Kazakh letter restored (а→ә, к→қ, и/ы→і…) | **−0.05** (shala typing is expected) |
| ё typed as е | 0 |
| Neighbouring-key swap / swapped letters | −1.0 |
| Missing or extra letter | −1.3 |
| Swap with a non-neighbouring key (search doesn't generate these; costed only if one comes from another source) | −2.0 |
| Completion (rest of the word not typed yet) | −0.3 flat, so whole words beat eager completions |
| Personal: learned word / often-typed word / known word pair | +0.7 / up to +0.5 / +0.5 |

Tune these weights on the evaluation sets (section 8), aiming at the release gates.

### 6.4 Auto-replace rules (v2, replacing fix spec C1)
These apply when space or punctuation commits the current word. `lit` is what was typed; `best` is the top candidate that differs from it.
1. **Text field and token checks** (section 3). If any applies, don't replace.
2. If `lit` is a real word (`kk.words` ∪ `ru.words` ∪ learned words) and isn't on the allow-list, **don't replace**.
3. If the pair `lit→best` was refused before, `best` is ignored, or `best` is marked `suggestOnly`, **don't replace**.
4. If `lit` is capitalised in mid-sentence (probably a name), **don't replace**.
5. **Shala restoration** (`fold(best) == fold(lit)` and `lit` has no Kazakh letters): replace if `score(best) − score(second) ≥ 0.5`. If two restorations are close, such as қол/көл with no context, only suggest.
6. **Typo correction:** replace only if `score(best) − score(lit as unknown) ≥ 2.0` (100 times more likely) **and** `best − second ≥ 0.5`.
7. Otherwise, only suggest.

Optional for v2.1, only once the evaluation shows at most 1 wrong replacement per 1,000 words: allow rule 2 to be overridden when a shala restoration is at least 1,000 times more frequent **and** the context prefers it by at least 30 times. This targets pairs like жана→жаңа and соз→сөз.

### 6.5 Suggestion bar (3 slots, Apple-style)
- **While typing a word:**
  - If a replacement is pending: left = the typed word in quotes, centre = the replacement (bold), right = the next-best candidate.
  - Otherwise: the three best candidates, the most likely in the centre.
  - **Bilingual rule:** if `0.3 < P_kk < 0.7`, the right slot must be the best candidate from the *other* language. For example, typing "ка" shows қандай · қалай · как.
- **After a space:** three next-word predictions in the sentence language. If the language is unclear, two in the likelier language and one in the other.
- Capitalise at the start of a sentence, and keep the user's capitalisation pattern.

### 6.6 Next-word prediction
- **Context:** the last two committed words, lower-cased and normalised.
- **Lookup:** three-word table `(w1, w2)` → top 5. If that gives fewer than 3, fall back to the two-word table `(w2)` → top 5. Then fall back to the most frequent words of the sentence language (sentence starters at the start of a sentence).
- **Model:**
  - Phase 2 starts with **plain counts + "Stupid Backoff"** (Brants et al., 2007): simple, and fine for ranking.
  - Compare it with Kneser-Ney smoothing (KenLM, used offline only) later.
  - Store only the top-5 next words per context. Score other words with fallback: unigram × 0.4.
- **Mixing languages:** train on the real mixed stream, so cross-language pairs are learned ("сәлем" → "как"). Drop candidates whose language disagrees with a confident sentence language, unless they're very likely.
- **Personal:** the user's word-pair counts are merged in with a boost.

### 6.7 Personalisation (on the phone only)
- **What's stored:**
  - learned words with counts (cap 5,000);
  - counts of committed words (cap 20k);
  - user word pairs (cap 50k);
  - refused pairs (cap 2,000).
- **Decay:** halve all counts every 30 days.
- **Signals:** tapping the typed-word suggestion means learn it; backspace-revert means refuse the pair and learn the word; a committed word increments its counts.
- **Contacts and shortcuts:** `requestSupplementaryLexicon` gives contact names (marked as proper nouns) and the user's iOS Text Replacements, which work as replacements exactly like iOS.
- **Where it lives:** the keyboard's own storage, with a mirror to the app group when Full Access is on. The app has a reset control (fix spec C2). Nothing is ever sent anywhere, which is allowed under rule 4.4.1 because it only improves the keyboard on the device.

---

## 7. Offline data pipeline (`tools/pipeline`, Python 3.12)

1. **Get the sources** (licences are checked per source; see the table below).
2. **Clean the text:**
   - normalise Unicode (NFC);
   - fix Latin look-alike letters (a→а, i→і, y→у, o→о, e→е, c→с, p→р, x→х);
   - strip markup and split into sentences;
   - drop lines where more than 30% of the letters are Latin, and drop duplicate lines;
   - keep case statistics, to detect proper nouns.
3. **Tag each word's language:** letters + dictionaries, bootstrapped from the existing 54k Kazakh list and a Russian list.
4. **Count:**
   - single words per language;
   - word pairs and triples over the mixed stream, which keeps real language mixing.
5. **Choose the vocabulary:**
   - Kazakh: the top 400k forms seen at least 3 times, plus Hunspell `kk_KZ` forms expanded with `unmunch` (a frequency floor for unseen forms), plus the cleaned 54k list.
   - Russian: the top 250k forms.
   - Flags: `suggestOnly` for profanity (from today's 0.95 entries plus a curated list); `properNoun` when the word is capitalised more than 90% of the time.
6. **Stripped index:** generate fold variants (and both и/ы for і), group word IDs, sort by frequency.
7. **Prefix table:** top 8 per language for every stripped prefix of 1–3 letters.
8. **N-gram tables:** keep contexts seen at least 3 times, keep the top-5 next words, squeeze scores into 8 bits, hash the contexts to 64 bits, write the binary file.
9. **Language-detection model:** letter-triple counts for Kazakh (proper **and** stripped copies) and Russian, with add-k smoothing, stored as one-byte values.
10. **Test sets:**
    - shala versions, with each Kazakh letter dropped with probability 0.9;
    - typo versions, with neighbouring-key noise on 3% of letters;
    - mixed sentences made from Kazakh–Russian sentence pairs by swapping matching phrases.
11. **Output:** `manifest.json` with checksums and the list of sources, plus `.idx` files. Commit the outputs, or attach them to a release.

| Source | Use | Licence notes |
|---|---|---|
| Kazakh and Russian Wikipedia | counts | CC BY-SA 4.0: use statistics only; credit in About |
| Web-crawl corpora (CC-100, OSCAR, MADLAD-400, CulturaX: Kazakh and Russian parts) | counts | Check each one's terms; use statistics only |
| ISSAI KazParC (Kazakh–Russian sentence pairs) | mixed-text generation, test sets | Licence not confirmed; check |
| ISSAI review datasets (Kazakh reviews with Russian words) | conversational counts | Check licence |
| Hunspell `kk_KZ` (already in the repo), `ru_RU` | word-form coverage | Check licences |
| KRCS (618 real mixed sentences) | **testing only** | Not allowed for training |
| ISSAI KazLLM; apertium-kaz | **do not ship anything derived from them** | Non-commercial (CC-BY-NC); GPL-3 |

---

## 8. Evaluation and release gates (`tools/eval`)

**Test sets (held out from training):**
- `kk_proper`: news and Wikipedia sentences, plus chat-style text where possible;
- `kk_shala`: synthetic, plus a small real set from volunteers who consent;
- `ru`;
- `mixed`: synthetic plus KRCS;
- typo versions of each.

**Simulator.** It types each sentence one letter at a time through `PredictionEngine`:
- If the intended word shows in the bar, it "taps" it, which counts toward keystrokes saved.
- When the word is finished, it presses space and records whether the auto-replacement was right or wrong.

| Metric | Gate |
|---|---|
| Wrong auto-replacements (correct word changed, or changed to the wrong word) | **≤ 1 per 1,000 words** on every set |
| Shala restored correctly on `kk_shala` | ≥ 90% |
| Keystrokes saved on chat-style Kazakh and Russian | ≥ 20% |
| Next word in the top 3 | track release to release; aim for ≥ 25% |
| Language detected correctly per word on `mixed` | ≥ 95% |
| Time per keystroke on the phone, 95% of keystrokes (XCTest measure, iPhone SE / 11) | ≤ 15 ms |
| Keyboard memory (Xcode gauge / Instruments) | ≤ 30 MB |

---

## 9. Integration with KeyboardKit 9
- **`QazaqAutocompleteProvider.autocomplete(_:)`:**
  - Build an `InputContext` from the text before the cursor.
  - Return predictions **also when the current word is empty**; today it returns `[]` at `:49`.
  - Mark only the winner of the replacement rules as `.autocorrect`; the typed word stays `.unknown`, everything else is `.regular`.
- **Undo and learning:** `QazaqActionHandler` (fix spec C2) for undo and refusals; `isAutolearnEnabled = true`.
- **Settings**, written by the app to the app group, which the keyboard can read without Full Access:
  - Languages: Kazakh + Russian (default) or Kazakh only;
  - Auto-correct on/off;
  - Restore Kazakh letters automatically on/off;
  - Predictive text on/off;
  - Reset learned words.
- **Keep KeyboardKit's remote next-word prediction off** (`nextWordPredictionRequestType` points to a remote AI API). We stay offline.

---

## 10. Rollout

| Phase | Weeks (part-time) | What's delivered | Exit criteria |
|---|---|---|---|
| 1 | 6–8 | Pipeline v1 (word lists, stripped index, prefix table, language model); engine v1 (file readers, language detection, completion/shala/typo search, ranking by frequency, replacement rules v2, bar); adapter; evaluation tool; TestFlight build behind an **in-app "New engine (beta)" switch** | All gates except next-word and keystrokes saved |
| 2 | 6 | N-gram tables and next-word prediction; context-aware ranking; personal model; contacts and Text Replacements; settings | All gates |
| 3 | later | Neural re-ranker on the top 20 candidates (Core ML, 8-bit, ≤ 5 MB); better Kazakh endings; swipe typing (Apple has none for Russian or Kazakh); Latin-alphabet Kazakh output | — |

- The beta switch is stored in the app group, and the keyboard reads it.
- The old engine stays as a fallback until Phase 1 passes its gates on TestFlight.

---

## 11. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Little conversational Kazakh text | Synthetic shala and mixed text; review datasets; on-phone learning; opt-in "add a missing word" in the app |
| Licences | Statistics only; source list in the manifest; avoid non-commercial and GPL data; a legal check before launch |
| Memory and speed on old phones | Memory-mapped files; candidate caps; budgets checked on an iPhone SE; skip typo search for words under 3 letters |
| Over-correction | Real words protected; margins; backspace undo; release gate at ≤ 1 wrong replacement per 1,000 words; auto-correct switch in settings |
| Language detection on very short words (2–3 letters) | Lean on context and dictionaries; words in both languages get suggestions in both; never auto-replace real words |
| App size (+40 MB) | Acceptable; prune n-grams harder if needed |
| KeyboardKit upgrades | The adapter isolates the engine |

---

## 12. Worked example
The user types: **"Салем как дела ертен кездесемиз бе"**

| Word | Evidence | Language | Result |
|---|---|---|---|
| Салем | no Kazakh letters; strips to сәлем (frequent); not a Russian word | kk ≈ 0.95 | lit isn't a real word, clear shala restoration → **Сәлем** (capital kept) |
| как | very frequent Russian word; stripped Kazakh match қақ is rare | ru ≈ 0.9 despite the previous word | real word → **keep**. Next-word after "как": дела, ты, раз |
| дела | predicted after "как"; the user taps it | ru | **дела** (5 keystrokes saved) |
| ертен | strips to ертең (frequent); not Russian | kk ≈ 0.9 | shala restoration → **ертең**. "ерт" probably already offered it |
| кездесемиз | matches кездесеміз through і→и | kk ≈ 0.97 | **кездесеміз** |
| бе | real Kazakh question particle | kk | **keep** |

Result: **"Сәлем как дела ертең кездесеміз бе"**, a correct mixed sentence with no keyboard switches.

---

## Sources
- [Apple ML Research: Language Identification from Very Short Strings](https://machinelearning.apple.com/research/language-identification-from-very-short-strings)
- [Jack Cook: A look at Apple's new Transformer-powered predictive text model](https://jackcook.com/2023/09/08/predictive-text.html)
- [9to5Mac: iOS 17 autocorrect](https://9to5mac.com/2023/06/05/ios-17-iphone-autocorrect/)
- [Apple ML Research: Learning with Privacy at Scale](https://machinelearning.apple.com/research/learning-with-privacy-at-scale)
- [Apple iPhone User Guide: predictive text](https://support.apple.com/en-asia/guide/iphone/use-predictive-text-iphd4ea90231/15.0/ios)
- [iDownloadBlog: multilingual typing on iPhone](https://www.idownloadblog.com/2017/01/16/how-to-multilingual-typing-iphone/)
- [Apple: iOS 27 feature availability](https://www.apple.com/ios/feature-availability/)
- [Ouyang et al.: Mobile Keyboard Input Decoding with Finite-State Transducers](https://arxiv.org/abs/1704.03987)
- [Hellsten et al.: Transliterated Mobile Keyboard Input via Weighted Finite-State Transducers](https://research.google/pubs/transliterated-mobile-keyboard-input-via-weighted-finite-state-transducers/)
- [Google Research: The Machine Intelligence Behind Gboard](https://www.research.google/blog/the-machine-intelligence-behind-gboard/)
- [KRCS mixed Kazakh–Russian dataset](https://arxiv.org/html/2503.20007v1)
- [ISSAI KazLLM licence](https://issai.nu.edu.kz/2024/12/10/official-release-of-the-issai-kaz-llm-open-source-model-is-available/)
- [apertium-kaz (GPL-3)](https://github.com/apertium/apertium-kaz)
- [Apple App Review Guidelines (4.4.1)](https://developer.apple.com/app-store/review/guidelines/)
- [Keyboard extension memory limit (React Native docs)](https://reactnative.dev/docs/app-extensions)
