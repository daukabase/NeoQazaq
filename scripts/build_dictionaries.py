#!/usr/bin/env python3
"""Build the keyboard's dictionary files from the source data.

The keyboard memory-maps these files and binary-searches them (see
SortedLinesFile.swift), so they must be sorted by raw UTF-8 bytes.

Inputs  (WordSuggestionsEngine/WordSuggestionsEngine/Recources/, not bundled):
  ShalaqazaqDatasetV2.json   typed-with-Russian-letters -> proper Kazakh map
  qazaqWordsList.txt         Kazakh word list
  russianWordsDataset.txt    small Russian word list (fallback for the spell checker)
  specs/data/autocorrect-conflicts.tsv   reviewed allow-list decisions

Outputs (same folder, bundled into WordSuggestionsEngine):
  shala.tsv                  "key\\tword:score|word:score" per line
  kk_words.txt               one lower-cased Kazakh word per line
  ru_words.txt               one lower-cased Russian word per line
  autocorrect_allowlist.txt  typed forms that must auto-correct even though they
                             appear in the Kazakh list (misspellings in the data)

Usage:  python3 scripts/build_dictionaries.py [--include-unverified]
Re-run whenever the source data or the review file changes, then commit the outputs.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "WordSuggestionsEngine", "WordSuggestionsEngine", "Recources")
REVIEW = os.path.join(ROOT, "specs", "data", "autocorrect-conflicts.tsv")

# Latin letters that look identical to Cyrillic ones (H8).
HOMOGLYPHS = str.maketrans({
    "a": "а", "e": "е", "o": "о", "p": "р", "c": "с", "x": "х", "y": "у", "i": "і",
    "A": "А", "E": "Е", "O": "О", "P": "Р", "C": "С", "X": "Х", "Y": "У", "I": "І",
    "K": "К", "M": "М", "H": "Н", "T": "Т", "B": "В",
})
LATIN = re.compile(r"[A-Za-z]")
CYRILLIC_WORD = re.compile(r"^[Ѐ-ӿ][Ѐ-ӿ\-']*$")


def clean(word: str) -> str | None:
    """Normalise one dictionary word; None if it should be dropped."""
    w = word.strip().translate(HOMOGLYPHS).lower()
    if not w or LATIN.search(w) or not CYRILLIC_WORD.match(w):
        return None
    return w


def utf8_sorted(items):
    return sorted(items, key=lambda s: s.encode("utf-8"))


def write_lines(path, lines):
    with open(path, "wb") as f:
        f.write(("\n".join(lines) + "\n").encode("utf-8"))


def load_allow_list(include_unverified: bool) -> set[str]:
    allow = set()
    with open(REVIEW, encoding="utf-8") as f:
        next(f)  # header
        for line in f:
            typed, _cands, action, confidence, *_ = line.rstrip("\n").split("\t") + [""]
            if action == "autocorrect" and (confidence in ("high", "reviewed") or include_unverified):
                allow.add(typed)
    return allow


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--include-unverified", action="store_true",
                    help="also allow rows marked confidence=verify")
    args = ap.parse_args()

    allow = load_allow_list(args.include_unverified)

    # Kazakh words: cleaned, lower-cased, minus reviewed misspellings.
    raw_kk = open(os.path.join(RES, "qazaqWordsList.txt"), encoding="utf-8").read().split("\n")
    kk = {c for c in (clean(w) for w in raw_kk) if c} - allow

    # Russian words: strip notes like "(See #663)", clean, dedupe.
    raw_ru = open(os.path.join(RES, "russianWordsDataset.txt"), encoding="utf-8").read().splitlines()
    ru = {c for c in (clean(re.sub(r"\(.*?\)", "", w)) for w in raw_ru) if c}

    # Map: clean keys and values; merge duplicates keeping the highest score.
    data = json.load(open(os.path.join(RES, "ShalaqazaqDatasetV2.json"), encoding="utf-8"))
    shala: dict[str, dict[str, float]] = {}
    for key, variations in data.items():
        k = clean(key)
        if not k:
            continue
        for word, score in variations.items():
            w = clean(word)
            if w:
                bucket = shala.setdefault(k, {})
                bucket[w] = max(score, bucket.get(w, 0.0))

    shala_lines = []
    for k in utf8_sorted(shala):
        parts = sorted(shala[k].items(), key=lambda kv: (-kv[1], kv[0]))
        shala_lines.append(k + "\t" + "|".join(f"{w}:{s:g}" for w, s in parts))

    write_lines(os.path.join(RES, "shala.tsv"), shala_lines)
    write_lines(os.path.join(RES, "kk_words.txt"), utf8_sorted(kk))
    write_lines(os.path.join(RES, "ru_words.txt"), utf8_sorted(ru))
    write_lines(os.path.join(RES, "autocorrect_allowlist.txt"), utf8_sorted(allow))

    print(f"shala.tsv: {len(shala_lines)} keys | kk_words.txt: {len(kk)} | "
          f"ru_words.txt: {len(ru)} | allow-list: {len(allow)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
