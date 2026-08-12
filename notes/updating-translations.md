# Design note: updating a translation when the help changes

Addresses two coupled review comments on rhelpi18n PR #36:

- **Item 16** (`translating.Rmd`): "This package should provide a function to update
  translations. It would generate a new skeleton, compare originals and copy over the
  translations for the strings that haven't changed."
- **Item 17** (review body): "We don't have any field to mark translations as stale *for
  translators*. If the original string changed, the translator would see the old translation
  and then modify it if needed. Right now that is not possible with our format."

They are one feature: **re-sync an existing translation module against a newer version of the
package it translates.**

## Key idea: compare *scaffolds*, not rendered help

The unit we compare is the scaffold `original` (static text + `{ISEXPR_i}` placeholders), not
the rendered page. So:

- A version bump that only changes a **baked value** (`R 4.5.3 → 4.6.0`, today's date, a
  regenerated table) does **not** change the scaffold → the translation stays valid, not flagged.
- Only a genuine **prose/structure change** (an edited sentence, a new/removed `\Sexpr`, an added
  argument) changes the scaffold → flagged.

This gives a low-noise "did the thing a translator cares about actually change?" signal for free.

## Precedent: gettext "fuzzy"

This is exactly what gettext/PO files have done for decades — source string changes, the old
translation is kept, and the entry is flagged `#, fuzzy` with the previous source retained
(`#| msgid`) so the translator edits rather than redoes. Tools (Weblate, poedit) surface fuzzy
entries for review. We adopt the same model and vocabulary — which is also what the R Contributors
translation community already uses.

## Decisions (locked)

1. Flag name: **`fuzzy`** (gettext-native).
2. The flag is **translator-only** — it does not change runtime behaviour (see below).
3. `i18n_module_update()` updates the module **in place**, with a **`dry_run`** option.
4. Sections that disappear from the new source are **dropped and reported**.

## Item 17 — the format

A section whose `original` changed after an update:

```yaml
description:
  original: <NEW scaffold>
  translation: <OLD translation, preserved>   # translator edits this, doesn't redo it
  previous_original: <OLD scaffold>            # so they can see exactly what changed
  fuzzy: true                                  # flag: needs review
```

- **Unchanged** section → just `original` + `translation` (no `fuzzy`/`previous_original`).
- **New** section → `translation: ~`.
- **Backward-compatible**: `match_and_fill` already ignores unknown YAML keys (same as `spans`),
  so `fuzzy`/`previous_original` do not affect the stored format the runtime reads.

### Relationship to the runtime `distance` metric

`match_and_fill` already returns `distance` (0 = valid, finite = drift, Inf = untranslated): a
translation whose stored scaffold no longer aligns with the *installed* help degrades at runtime.
That is the **runtime** staleness signal. `fuzzy` is its **authoring-time** counterpart — set when
the *source* changed since the translator last touched the section. They measure the same thing at
different times against different references, so we keep both and do **not** wire `fuzzy` into the
runtime for now. (A future option: "runtime shows the original for `fuzzy` sections," if we ever
want to be conservative.)

## Item 16 — `i18n_module_update()`

```r
i18n_module_update(module_path, package_path, dry_run = FALSE)
```

1. Regenerate a fresh skeleton from the **new** `package_path` (temp dir), reusing the
   `i18n_module_create()` internals.
2. Merge, per page → per section (and per `\arguments` item):

   | old vs. new | action |
   |---|---|
   | old exists, `original` **same** | carry over `translation` **and** its `ifdef` sub-translations; refresh the `spans` hint to the new example values |
   | old exists, `original` **changed** | new `original`; keep old `translation`; add `previous_original` + `fuzzy: true` |
   | no old (new section/page) | `translation: ~` |
   | old exists, gone from new | drop, and list it in the report |

3. Refresh `man_original/` to the new source; bump `Translates: <pkg> (== <newversion>)`.
4. Print a summary: `N unchanged, M fuzzy, K new, J dropped`.

With `dry_run = TRUE`, steps 1–2 run but nothing is written — only the summary is printed. Updating
in place is safe because the module is a git repo: the translator diffs and reverts as needed.

### Details that are easy to miss

- **Carry-over must include `ifdef` sub-translations**, not just `translation`.
- **Refresh `spans`** even on unchanged sections, so the example values stay current.
- Matching is by **section name** (and argument-item name) within a page; a section whose content
  moved elsewhere reads as a drop + a new/fuzzy section, which the translator resolves.

## Edge cases / open questions

- **Pipeline changes:** if `detect_scaffolds`/`rd_flatten` formatting changes between rhelpi18n
  versions, *every* section could look "changed" and be flagged fuzzy. Mitigation: only compare
  scaffolds produced by the same generator; note this as a known caveat.
- **Placeholder renumbering:** inserting an earlier `\Sexpr` renumbers later `{ISEXPR_i}` → the
  scaffold changes → fuzzy. Correct — the translator must re-check placeholder positions anyway.
- **Source acquisition:** `i18n_module_update()` takes a local `package_path` (like
  `i18n_module_create()`); fetching source from CRAN is out of scope here (that lives on the parked
  `install-with-translation-cran` branch).

## Scope / non-goals

- No change to the runtime or to how installed modules are discovered.
- No CRAN/network fetching.
- No automatic (machine) re-translation of fuzzy entries — a human reviews them.
