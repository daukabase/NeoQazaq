#!/usr/bin/env python3
"""Build the predictive-text data (word completion + next word) from Wikipedia dumps.

This is the "training" step of a statistical language model: it counts how often words and
word pairs occur. No neural network, no GPU. Runs in minutes on a laptop.

Inputs (download first; not committed):
  kkwiki-latest-pages-articles.xml.bz2          https://dumps.wikimedia.org/kkwiki/latest/
  ruwiki-latest-pages-articles1.xml-p1p224167.bz2  https://dumps.wikimedia.org/ruwiki/latest/
Wikipedia text is CC BY-SA 4.0. Only word statistics are shipped; credit Wikipedia in the app.

Outputs (WordSuggestionsEngine/WordSuggestionsEngine/Recources/, bundled, memory-mapped):
  complete_kk.tsv / complete_ru.tsv   "foldedWord\\tword\\tscore" sorted by folded bytes, then score desc.
                                      Prefix search on the folded column finds shala input too
                                      ("кан" → қандай). score = 0..255 (log frequency).
  prefix_top.tsv                      "lang:foldedPrefix\\tword|word|…" top words for 1–3 letter prefixes,
                                      plus "lang=exactPrefix" lists for prefixes with Kazakh letters or ё
  next_words.tsv                      "previousWord\\tword|word|…" top next words;
                                      sentence starters under "<s>:kk" and "<s>:ru"

Usage:
  python3 scripts/build_frequencies.py --kk path/to/kkwiki.xml.bz2 --ru path/to/ruwiki1.xml.bz2
"""
from __future__ import annotations

import argparse
import bz2
import math
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "WordSuggestionsEngine", "WordSuggestionsEngine", "Recources")

KAZAKH_ONLY = set("әғқңөұүһі")
# Kazakh letters → what people type without them. і is typed as и or ы; both are indexed.
FOLD = str.maketrans({"ә": "а", "ғ": "г", "қ": "к", "ң": "н", "ө": "о", "ұ": "у", "ү": "у", "һ": "х", "ё": "е"})
HOMOGLYPHS = str.maketrans({"a": "а", "e": "е", "o": "о", "p": "р", "c": "с", "x": "х", "y": "у", "i": "і"})

WORD = re.compile(r"[а-яёәғқңөұүһі]+(?:-[а-яёәғқңөұүһі]+)?")
SENTENCE_END = re.compile(r"[.!?…]+\s|\n")
DIGIT = re.compile(r"\d")

# Wikitext cleanup (good enough for counting).
RE_TEXT = re.compile(r"<text[^>]*>(.*?)</text>", re.S)
RE_NS = re.compile(r"<ns>(\d+)</ns>")
RE_REDIRECT = re.compile(r"<redirect")
RE_COMMENT = re.compile(r"&lt;!--.*?--&gt;", re.S)
RE_REF = re.compile(r"&lt;ref[^&]*?/&gt;|&lt;ref.*?&lt;/ref&gt;", re.S)
RE_TAG = re.compile(r"&lt;[^&]*?&gt;")
RE_TEMPLATE = re.compile(r"\{\{[^{}]*\}\}")
RE_TABLE = re.compile(r"\{\|.*?\|\}", re.S)
RE_FILE = re.compile(r"\[\[(?:Файл|File|Сурет|Image|Изображение|Санат|Category|Категория):[^\]]*\]\]", re.I)
RE_LINK = re.compile(r"\[\[(?:[^\]|]*\|)?([^\]]*)\]\]")
RE_EXT = re.compile(r"\[https?://[^\s\]]*\s?([^\]]*)\]")
RE_ENTITY = re.compile(r"&[a-z]+;|&#\d+;")
RE_GALLERY = re.compile(r"&lt;gallery.*?&lt;/gallery&gt;", re.S | re.I)
RE_FILE_LINE = re.compile(r"^\s*(?:Файл|File|Сурет|Image|Изображение)\s*:", re.I)


def fold_variants(word: str) -> list[str]:
    """Folded forms of a word; і produces both и and ы variants (capped)."""
    base = word.translate(FOLD)
    variants = [""]
    for ch in base:
        if ch == "і":
            variants = [v + r for v in variants for r in ("и", "ы")][:8]
        else:
            variants = [v + ch for v in variants]
    return variants


def clean_wikitext(text: str) -> str:
    text = RE_COMMENT.sub(" ", text)
    text = RE_GALLERY.sub(" ", text)
    text = RE_REF.sub(" ", text)
    for _ in range(3):  # nested templates
        text = RE_TEMPLATE.sub(" ", text)
    text = RE_TABLE.sub(" ", text)
    text = RE_FILE.sub(" ", text)
    text = RE_LINK.sub(r"\1", text)
    text = RE_EXT.sub(r"\1", text)
    text = RE_TAG.sub(" ", text)
    text = RE_ENTITY.sub(" ", text)
    text = text.replace("'''", "").replace("''", "")
    lines = [l for l in text.split("\n") if l and not l.startswith(("=", "*", "#", "|", "!", "{", ":", ";")) and not RE_FILE_LINE.match(l)]
    return "\n".join(lines)


def articles(path: str, limit: int | None):
    """Yield cleaned article texts from a MediaWiki XML dump (main namespace, no redirects)."""
    buf = []
    count = 0
    with bz2.open(path, "rt", encoding="utf-8", errors="ignore") as f:
        for line in f:
            buf.append(line)
            if "</page>" in line:
                page = "".join(buf)
                buf = []
                ns = RE_NS.search(page)
                if not ns or ns.group(1) != "0" or RE_REDIRECT.search(page):
                    continue
                m = RE_TEXT.search(page)
                if m:
                    yield clean_wikitext(m.group(1))
                    count += 1
                    if limit and count >= limit:
                        return


def count_corpus(path: str, lang: str, limit: int | None):
    words: Counter[str] = Counter()
    pairs: Counter[tuple[str, str]] = Counter()
    sentences = 0
    for n, text in enumerate(articles(path, limit), 1):
        for sentence in SENTENCE_END.split(text.lower().translate(HOMOGLYPHS)):
            # Skip sentences with digits: mostly date/statistics boilerplate from stub articles
            # ("1990 жылы …"), which would make every prediction about years and months.
            if DIGIT.search(sentence):
                continue
            tokens = WORD.findall(sentence)
            if len(tokens) < 3:
                continue
            letters = "".join(tokens)
            has_kz = any(c in KAZAKH_ONLY for c in letters)
            # Keep only sentences in the corpus language (Kazakh pages quote Russian and vice versa).
            if lang == "kk" and not has_kz:
                continue
            if lang == "ru" and has_kz:
                continue
            sentences += 1
            words.update(tokens)
            prev = "<s>"
            for t in tokens:
                pairs[(prev, t)] += 1
                prev = t
        if n % 20000 == 0:
            print(f"  {lang}: {n} articles, {sentences} sentences, {len(words)} words, {len(pairs)} pairs", flush=True)
            if len(pairs) > 12_000_000:  # keep memory bounded: drop rare pairs
                pairs = Counter({k: v for k, v in pairs.items() if v > 1})
    return words, pairs, sentences


def score(count: int, max_count: int) -> int:
    """Log-frequency squeezed into 1..255."""
    return max(1, min(255, round(255 * math.log(count + 1) / math.log(max_count + 1))))


def write(path: str, lines: list[str]) -> None:
    with open(path, "wb") as f:
        f.write(("\n".join(lines) + "\n").encode("utf-8"))
    print(f"  wrote {os.path.basename(path)}: {len(lines)} lines, {os.path.getsize(path) / 1e6:.1f} MB")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--kk", required=True)
    ap.add_argument("--ru", required=True)
    ap.add_argument("--vocab", type=int, default=150_000, help="words kept per language")
    ap.add_argument("--min-count", type=int, default=3)
    ap.add_argument("--next", type=int, default=5, help="next-word candidates per context")
    ap.add_argument("--contexts", type=int, default=120_000, help="next-word contexts kept per language")
    ap.add_argument("--limit", type=int, default=None, help="articles per dump (for quick tests)")
    args = ap.parse_args()

    profanity = set()
    allow = os.path.join(RES, "shala.tsv")
    if os.path.exists(allow):  # entries scored exactly 0.95 are never-auto words (vulgar); never predict them
        for line in open(allow, encoding="utf-8"):
            key, _, values = line.rstrip("\n").partition("\t")
            for part in values.split("|"):
                word, _, s = part.rpartition(":")
                if s == "0.95" and word != "қазақ":
                    profanity.add(word)

    # scripts/data/chat_words.txt: "# Kazakh" and "# Russian" sections, one word per line.
    chat_words: dict[str, list[str]] = {"kk": [], "ru": []}
    chat_path = os.path.join(ROOT, "scripts", "data", "chat_words.txt")
    section = None
    for line in (open(chat_path, encoding="utf-8") if os.path.exists(chat_path) else []):
        line = line.strip()
        if line.lower().startswith("# kazakh"):
            section = "kk"
        elif line.lower().startswith("# russian"):
            section = "ru"
        elif line and not line.startswith("#") and section:
            chat_words[section].append(line.lower())

    prefix_top: dict[str, list[tuple[int, str]]] = defaultdict(list)
    next_lines: dict[str, tuple[int, list[tuple[float, str]]]] = {}

    for lang, path in (("kk", args.kk), ("ru", args.ru)):
        print(f"Counting {lang} from {path}", flush=True)
        words, pairs, sentences = count_corpus(path, lang, args.limit)
        vocab = [(w, c) for w, c in words.most_common(args.vocab) if c >= args.min_count and w not in profanity and len(w) > 1
                 and all(len(part) >= 2 for part in w.split("-"))
                 # Russian words quoted inside Kazakh sentences: they belong to the Russian list.
                 and not (lang == "kk" and any(ch in "ёъщэ" for ch in w))]
        top = vocab[0][1]
        scores = {w: score(c, top) for w, c in vocab}
        # Chat words Wikipedia under-represents (scripts/data/chat_words.txt): boost into the top range.
        for w in chat_words[lang]:
            scores[w] = max(scores.get(w, 0), 235)
        print(f"  {lang}: {sentences} sentences, kept {len(vocab)} of {len(words)} words", flush=True)

        rows = []
        for w, s in scores.items():
            for folded in fold_variants(w):
                rows.append((folded, -s, w))
                for n in (1, 2, 3):
                    if len(folded) >= n:
                        prefix_top[f"{lang}:{folded[:n]}"].append((s, w))
            # Typed prefixes that already contain Kazakh letters (or ё) get their own exact lists ("kk=қа").
            for n in (1, 2, 3):
                exact = w[:n]
                if len(w) >= n and any(c in KAZAKH_ONLY or c == "ё" for c in exact):
                    prefix_top[f"{lang}={exact}"].append((s, w))
        rows.sort(key=lambda r: (r[0].encode("utf-8"), r[1], r[2].encode("utf-8")))
        write(os.path.join(RES, f"complete_{lang}.tsv"), [f"{f}\t{w}\t{-ns}" for f, ns, w in rows])

        # Next words: P(next | previous) ranked by count, contexts limited to the vocabulary.
        by_prev: dict[str, list[tuple[int, str]]] = defaultdict(list)
        for (prev, nxt), c in pairs.items():
            if c >= args.min_count and nxt in scores and (prev == "<s>" or prev in scores):
                by_prev[prev].append((c, nxt))
        contexts = sorted(by_prev.items(), key=lambda kv: -sum(c for c, _ in kv[1]))[: args.contexts]
        for prev, cands in contexts:
            if prev == "<s>":  # sentence starters stay per language ("<s>:kk", "<s>:ru")
                prev = f"<s>:{lang}"
            best = sorted(cands, key=lambda x: -x[0])[: args.next]
            total = sum(c for c, _ in cands)
            ranked = [(c / total, w) for c, w in best]
            if prev in next_lines:  # the word exists in both languages
                other_total, other = next_lines[prev]
                if total < 0.2 * other_total:      # rare here: keep the other language's predictions
                    continue
                if other_total < 0.2 * total:      # rare there: replace them
                    next_lines[prev] = (total, ranked)
                    continue
                merged = sorted(other + ranked, key=lambda x: -x[0])
                seen = set()
                ranked = [(p, w) for p, w in merged if not (w in seen or seen.add(w))][: args.next]
                total = max(total, other_total)
            next_lines[prev] = (total, ranked)
        del words, pairs

    prefix_lines = []
    for key in sorted(prefix_top, key=lambda k: k.encode("utf-8")):
        seen, best = set(), []
        for s, w in sorted(prefix_top[key], key=lambda x: -x[0]):
            if w not in seen:
                seen.add(w)
                best.append(w)
            if len(best) == 6:
                break
        prefix_lines.append(f"{key}\t{'|'.join(best)}")
    write(os.path.join(RES, "prefix_top.tsv"), prefix_lines)

    write(os.path.join(RES, "next_words.tsv"),
          [f"{prev}\t{'|'.join(w for _, w in ranked)}" for prev, (_, ranked) in
           sorted(next_lines.items(), key=lambda kv: kv[0].encode("utf-8"))])
    return 0


if __name__ == "__main__":
    sys.exit(main())
