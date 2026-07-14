# Tests for rhelpi18n:::match_and_fill(live, stored, translation, ifdef).
# Just strings, no translation module. Source in RStudio; each case prints PASS/FAIL.
library(rhelpi18n)
mf <- rhelpi18n:::match_and_fill

case <- function(name, live, stored, translation, expect, ifdef = NULL)
  list(name = name, live = live, stored = stored, translation = translation,
       expect = expect, ifdef = ifdef)

cases <- list(
  case("no token: exact match",          "abc",         "abc",                     "xyz",                     "xyz"),
  case("no token: drift -> live",         "abd",         "abc",                     "xyz",                     "abd"),
  case("one token fills value",           "on Monday",   "on {ISEXPR_0}",           "el {ISEXPR_0}",           "el Monday"),
  case("token at start",                  "Xyz",         "{ISEXPR_0}yz",            "{ISEXPR_0}ZZ",            "XZZ"),
  case("token at end",                    "ab7",         "ab{ISEXPR_0}",            "cd{ISEXPR_0}",            "cd7"),
  case("empty captured value",            "ab",          "a{ISEXPR_0}b",            "x{ISEXPR_0}y",            "xy"),
  case("multi-line value",                "a\nL1\nL2\nb", "a{ISEXPR_0}b",           "x{ISEXPR_0}y",            "x\nL1\nL2\ny"),
  case("regex-special value stays literal","id=[a-z]+$", "id={ISEXPR_0}",           "id={ISEXPR_0}",           "id=[a-z]+$"),
  case("two tokens fill",                 "a1b2c",       "a{ISEXPR_0}b{ISEXPR_1}c", "A{ISEXPR_0}B{ISEXPR_1}C", "A1B2C"),
  case("adjacent tokens: first empty",    "xVALy",       "x{ISEXPR_0}{ISEXPR_1}y",  "p{ISEXPR_0}{ISEXPR_1}q",  "pVALq"),
  case("prefix mismatch -> live",         "zzz",         "a{ISEXPR_0}c",            "A{ISEXPR_0}C",            "zzz"),
  case("interior anchor missing -> live", "a?c",         "a{ISEXPR_0}b{ISEXPR_1}c", "A{ISEXPR_0}B{ISEXPR_1}C", "a?c"),
  case("suffix mismatch -> live",         "aXYd",        "a{ISEXPR_0}c",            "A{ISEXPR_0}C",            "aXYd"),
  case("NULL stored -> live",             "abc",         NULL,                      "xyz",                     "abc"),
  case("NULL translation -> live",        "abc",         "abc",                     NULL,                      "abc"),
  case("ifdef: active branch translated", "pre SHOWN post",                  "pre {ISEXPR_0} post", "PRE {ISEXPR_0} POST", "PRE ES POST",                        ifdef = list("0" = "ES")),
  case("ifdef: inactive branch kept",     "pre #ifdef windows not active post", "pre {ISEXPR_0} post", "PRE {ISEXPR_0} POST", "PRE #ifdef windows not active POST", ifdef = list("0" = "ES")),
  case("escaped literal preserved",       "a {ISEXPR_0} b",        "a {{ISEXPR_0}} b",             "c {{ISEXPR_0}} d",            "c {ISEXPR_0} d"),
  case("real token + escaped literal",    "v=VAL lit={ISEXPR_9}",  "v={ISEXPR_0} lit={{ISEXPR_9}}", "x={ISEXPR_0} y={{ISEXPR_9}}", "x=VAL y={ISEXPR_9}")
)

pass <- 0L
for (c in cases) {
  got <- mf(c$live, c$stored, c$translation, c$ifdef)
  ok  <- identical(got, c$expect)
  pass <- pass + ok
  cat(if (ok) "PASS  " else "FAIL  ", c$name, "\n", sep = "")
  if (!ok) cat("      expect: ", encodeString(c$expect), "\n      got:    ", encodeString(got), "\n", sep = "")
}
cat(sprintf("\n%d / %d passed\n", pass, length(cases)))

# --- optional: details = TRUE returns list(text, reason, distance) ------------
# reason: "valid" | "stale" | "untranslated". distance: 0 for valid, coarse drift
# for stale, NA otherwise. Nothing reads these yet; forward-looking metadata.
cat("\ndetails = TRUE -> list(text, reason, distance):\n")
dcases <- list(
  list("valid",        "on Monday",      "on {ISEXPR_0}",     "el {ISEXPR_0}",     "valid"),
  list("stale",        "put at Tuesday", "put on {ISEXPR_0}",  "puesto {ISEXPR_0}", "stale"),
  list("untranslated", "on Monday",      "on {ISEXPR_0}",      NULL,                "untranslated")
)
dpass <- 0L
for (x in dcases) {
  r  <- mf(x[[2]], x[[3]], x[[4]], details = TRUE)
  ok <- identical(r$reason, x[[5]])
  dpass <- dpass + ok
  cat(if (ok) "PASS  " else "FAIL  ", "reason=", r$reason,
      "  distance=", r$distance, "  text=", encodeString(r$text), "\n", sep = "")
}
cat(sprintf("%d / %d reason checks passed\n", dpass, length(dcases)))
