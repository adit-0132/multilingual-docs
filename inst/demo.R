# =====================================================================
# rhelpi18n dynamic-Sexpr translation — end-to-end demo
# Run section by section in RStudio. RESTART R first (Ctrl+Shift+F10) so
# no stale namespaces/help caches are around. Do NOT reinstall a package
# and use its help in the same session (it corrupts the lazy-load .rdb).
# The R 4.5 library at ~/R/x86_64-redhat-linux-gnu-library/4.5 must be on
# .libPaths()[1].
# =====================================================================

## ---- 0. Setup -------------------------------------------------------
library(rhelpi18n)      # patches utils:::.getHelpFile   (R/zzzz.R .onLoad)
library(gsocproposal)   # the demo package
# the detector lives in the demo package's inst/ (source it; re-source after edits):
source("~/Projects/0-multilingual/multilingual-docs/inst/detect_install_sexpr.R")


## ---- 1. Install-Sexpr translation, and it survives value drift ------
Sys.setenv(LANGUAGE = "es"); ?greet     # Spanish; Details shows the LIVE install timestamp
Sys.setenv(LANGUAGE = "en"); ?greet     # English, for contrast

# Prove the translation survives the install value drifting — WITHOUT reinstalling
# (detect_install_sexpr re-bakes Sys.time() each call, so d1/d2 come from different
# baked values, yet the scaffold fingerprint is identical):
d1 <- detect_install_sexpr("greet")$details$fingerprint
Sys.sleep(2)
d2 <- detect_install_sexpr("greet")$details$fingerprint
identical(d1, d2)                        # TRUE


## ---- 2. Multi-line Sexpr (nested braces) ----------------------------
print_install_sexpr(detect_install_sexpr("stress_multiline"))
# {ISEXPR_1} captures the whole  if (...) { ... } else { ... }  block —
# the old  \{[^}]*\}  regex truncated it at the first inner "}".


## ---- 3. User-defined macros (de-doubled) ----------------------------
print_install_sexpr(detect_install_sexpr("usermacro"))
# "Google Summer of Code" appears ONCE (was doubled before the to_text fix).


## ---- 4. #ifdef / #ifndef branch translation -------------------------
Sys.setenv(LANGUAGE = "es"); ?ifndef     # active branch renders in SPANISH
Sys.setenv(LANGUAGE = "en"); ?ifndef     # English
# preview the OTHER platform's branch from this machine (no Windows box needed):
print_install_sexpr(detect_install_sexpr("ifndef", defines = "windows"))


## ---- 5. Stress harness (robustness + no false positives) ------------
source("~/Projects/0-multilingual/multilingual-docs/inst/stress_test.R")   # "108 / 108 checks passed"


## ---- 6. REAL CRAN package: auto-fetch source + build-stage Sexpr ----
library(xml2)
pkg <- "xml2"
ver <- packageDescription(pkg)$Version                 # from the INSTALLED binary
packageDescription(pkg)$Repository                     # "CRAN"
dest <- file.path(tempdir(), sprintf("%s_%s.tar.gz", pkg, ver))
# deterministic CRAN URL; current path first, Archive fallback for superseded versions:
for (u in c(sprintf("https://cran.r-project.org/src/contrib/%s_%s.tar.gz", pkg, ver),
            sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s_%s.tar.gz", pkg, pkg, ver)))
  if (tryCatch({ download.file(u, dest, quiet = TRUE, mode = "wb"); file.size(dest) > 2000 },
               error = function(e) FALSE)) break
untar(dest, exdir = tempdir())
srcdir <- file.path(tempdir(), pkg)

# the build \Sexpr is still LIVE in the CRAN source (R CMD build does not bake it):
grep("Sexpr", readLines(file.path(srcdir, "man", "read_xml.Rd")), value = TRUE)

# detector tokenises it (it sits inside the `options` argument, an \arguments \item):
det <- detect_install_sexpr("read_xml", src_dir = srcdir)$arguments$options
det$scaffold                             # "...Zero or more of {ISEXPR_0}"

# the scaffold matches the INSTALLED binary, so the runtime captures the real value:
live <- rhelpi18n:::rd_flatten(tools::Rd_db("xml2")[["read_xml.Rd"]])$arguments$options$original
identical(rhelpi18n:::match_and_fill(live, det$scaffold, det$scaffold), live)   # TRUE


## ---- 7. Render stage from the BINARY ALONE (no source) --------------
# render \Sexpr stay LIVE in the compiled .rdb, so they need no source:
count_render <- function(rd) { n <- 0
  w <- function(x) { if (identical(attr(x, "Rd_tag"), "\\Sexpr") &&
                         grepl("stage=render", attr(x, "Rd_option"))) n <<- n + 1
                     if (is.list(x)) for (c in x) w(c) }
  w(rd); n }
count_render(tools::Rd_db("dplyr")[["arrange.Rd"]])     # 1 — detectable straight from the binary


## ---- 8. One-call module creation: install_with_translation() ---------
# rhelpi18n::install_with_translation() does the whole pipeline for a CRAN
# package from just the installed binary: fetch matching source -> diff
# source vs installed Rd_db -> per-topic {ISEXPR_i} scaffolds -> translate
# static text -> build + install the `pkg.<lang>` module.
#
# `translate` is a pluggable function(text)->text; it only sees the literal
# text BETWEEN placeholders, so it can't corrupt a token. Here we fake it with
# an "[es] " prefix to make the translation visible end to end.
mod <- rhelpi18n::install_with_translation(
  "xml2", "es", translate = function(s) paste0("[es] ", s))

# inspect what the runtime produces for read_xml's `options` argument (the
# build \Sexpr): translated prose AND the real live options list from the binary
ns <- asNamespace("rhelpi18n")
tr   <- get("translations", asNamespace("xml2.es"))[["read_xml"]]
live <- get("rd_flatten", ns)(tools::Rd_db("xml2")[["read_xml.Rd"]])
cat(substr(get("translate", ns)(live, tr)$arguments$options, 1, 200), "\n")
# -> "[es] Set parsing options ... Zero or more of \describe{\item{RECOVER}...}"
# (translate = NULL instead would install a ready-to-fill template.)
