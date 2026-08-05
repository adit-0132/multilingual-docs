# Review questions — investigation & answers (RCWG + Heather)

Factual answers to the reviewers' questions about the rhelpi18n runtime, from a
read-through of the code + a few `Rscript` checks. File references are to
`rhelpi18n/R/`. Two of the notes were **build items done this cycle** and are
marked as such; the rest are answers plus (deferred) recommendations.

The runtime patches `utils:::.getHelpFile` in `.onLoad` (`zzzz.R`), so on every
`?topic` the patched function calls `.translateHelpFile(rd, pkgname, file, language)`
(`getHelpFile-shim.R`), which consults `get_translation_modules()` and, if a
module matches, runs `rd_translate()`.

---

## 1. Does it affect help for packages with no translation? (Heather)

**No — untranslated help is byte-identical to stock R.** `.translateHelpFile`
(`getHelpFile-shim.R`) has three early returns of the original `rd`:

- `if (is.null(language)) return(rd)`
- `if (length(translation_modules) == 0) return(rd)` — the path taken when the
  package has no translation module
- `if (is.null(translations)) return(rd)` — module matched the package but has no
  entry for this topic

When nothing matches, `rd_translate()` is never reached.

**Caveat + recommendation (deferred):** `get_translation_modules()` runs on
*every* help lookup and calls `pkgload::parse_deps()` on the `Translates:` field
of *every* installed translation module. A malformed `Translates:` field in some
*unrelated* installed module could therefore raise an error on `?anything`.
Recommend wrapping that scan in `tryCatch` so a broken third-party module can't
break the help system. (Not changed this cycle.)

## 2. Does it overwrite the original `?help`? Can the user still get it? (RCWG)

**Yes, it replaces the shown sections** (except `examples`/`title`, which keep
the original behind an HTML `<details>` disclosure — `rd-translate.R`). There is
**no per-page switch** to request English.

**How to get the original:** resolve the language to something with no installed
module. `LANGUAGE`'s default is `"en"` (`Sys.getenv("LANGUAGE", "en")`), so
`Sys.setenv(LANGUAGE = "en")` (or unsetting it) yields the untranslated help
(assuming no `en` module is installed).

**Recommendation (deferred):** consider an explicit escape hatch — e.g. a
`getOption("rhelpi18n.disable")` or a `?en:topic`-style prefix — so a user can
see the original without changing their global `LANGUAGE`.

## 3. Same function name across packages — does help disambiguation still work? (RCWG + Heather)

**Yes, it works, with no new ambiguity.** Stock `.getHelpFile(file)` derives the
package from the file path: `pkgname <- basename(dirname(dirname(file)))`. The
shim (`zzzz.R`) adds, via `on.exit`, a call that passes those already-computed
`pkgname` and `file` locals to `.translateHelpFile`. R's help system resolves
`?filter` to a *specific* package+topic (its usual disambiguation menu/selection)
**before** `.getHelpFile` is ever called, so the shim only ever sees the
already-chosen path. `get_translation_modules(pkgname, …)` then matches modules
whose `Translates:` name equals that exact package (`stats` vs `dplyr`), and the
right one is translated. The shim inherits R's resolution; it introduces no new
ambiguity.

## 4. Multiple packages with the same name at once? (RCWG)

- The **target** package is never looked up here — it's matched only by string
  equality (`translates == package`), so a shadowed target name is a non-issue.
- **Translation modules** *can* collide across `.libPaths()`: if the same module
  is installed in two libraries, `installed.packages()` returns two matching
  rows and `.translateHelpFile` uses `translation_modules[1]` while
  `asNamespace()` loads whichever copy the search path resolves — a possible
  "first wins" mismatch. Rare (needs shadowing across lib paths); worth a note,
  not urgent. R cannot host two packages of the same name in a single library.

## 5. `Sys.setlanguage()` instead of `Sys.setenv(LANGUAGE=)`? (Heather)

**Base R already provides it.** The lowercase `Sys.setlanguage()` does not exist,
but **`Sys.setLanguage()`** (capital L, base R since 4.2.0, exported) does: it is
a guarded wrapper around `Sys.setenv(LANGUAGE = lang)` that also returns the
previous value (so `on.exit(Sys.setLanguage(old))` works). It is the idiomatic
way to set the help language, and the vignettes now use it — no custom helper is
needed.

*Caveat:* `Sys.setLanguage()` early-returns without setting `LANGUAGE` when
`capabilities("NLS")` is `FALSE` or the locale is `C`/`POSIX`. rhelpi18n's help
translation reads only the `LANGUAGE` variable and needs no NLS, so in those
environments `Sys.setenv(LANGUAGE = ...)` still works as a direct fallback.

---

## Notes that were build items this cycle

- **"Document what `{ISEXPR_n}` originally stored" (RCWG) / "carry forward
  verbatim text" (Heather):** done. `i18n_module_skeleton()` now writes a
  per-section `spans:` map (token index → an *example* of the baked value at
  generation time) into each YAML, so translators can see what each placeholder
  represents. Documented as an example (the real value differs per install).

## Notes that confirm the current design (no change)

- **"Use a separate package for translations" (Heather):** that is already the
  architecture — each translation is its own installable module, discovered by
  its `Translates:` + `Language:` DESCRIPTION fields, so different maintainers
  can own them and users install only the language they need.
