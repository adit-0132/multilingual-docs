# Stress harness for the install-Sexpr detector + runtime match.
# For each topic, runs detect_install_sexpr() and checks, per section:
#   - roundtrip : refilling the scaffold with the captured values reproduces the
#                 live `original` exactly  (no-op identity)
#   - stability : the scaffold is identical across two detect runs even when a
#                 volatile install Sexpr (e.g. Sys.time) bakes a different value
#   - tokencount: number of placeholder tokens in the scaffold == number of spans
#                 (a guard against spurious / false-positive tokens)
# Run:  Rscript multilingual-docs/inst/stress_test.R
suppressMessages(library(rhelpi18n))
HERE <- path.expand("~/Projects/0-multilingual/multilingual-docs")
source(file.path(HERE, "inst", "detect_install_sexpr.R"))

match_and_fill <- get("match_and_fill", envir = asNamespace("rhelpi18n"))

# count placeholder tokens; keep in sync with the detector's sentinel
TOKEN_RE <- "\\{ISEXPR_[0-9]+\\}"
ntok <- function(s) { m <- gregexpr(TOKEN_RE, s)[[1]]; if (m[1] == -1) 0L else length(m) }

# flatten a detect result into scaffold leaves (recurses into \arguments items)
leaves <- function(r, pfx = "") {
  out <- list()
  for (nm in names(r)) {
    x <- r[[nm]]; key <- if (nzchar(pfx)) paste0(pfx, "/", nm) else nm
    if (!is.null(x$scaffold)) out[[key]] <- x
    else if (is.list(x)) out <- c(out, leaves(x, key))
  }
  out
}

check_topic <- function(topic) {
  res  <- tryCatch(detect_install_sexpr(topic), error = function(e) e)
  if (inherits(res, "error"))
    return(data.frame(topic, section = "*", test = "detect", ok = FALSE,
                      note = conditionMessage(res), stringsAsFactors = FALSE))
  res2 <- tryCatch(detect_install_sexpr(topic), error = function(e) NULL)
  L  <- leaves(res)
  L2 <- if (is.null(res2)) list() else leaves(res2)
  rows <- list()
  add <- function(sec, test, ok, note = "")
    rows[[length(rows) + 1]] <<- data.frame(topic, section = sec, test = test,
                                            ok = ok, note = note, stringsAsFactors = FALSE)
  for (sec in names(L)) {
    r  <- L[[sec]]
    rt <- tryCatch(match_and_fill(r$original, r$scaffold, r$scaffold)$text,
                   error = function(e) paste("ERR:", conditionMessage(e)))
    add(sec, "roundtrip",  identical(rt, r$original),
        if (identical(rt, r$original)) "" else "refilled scaffold != original")
    add(sec, "stability",  !is.null(L2[[sec]]) && identical(r$scaffold, L2[[sec]]$scaffold))
    add(sec, "tokencount", ntok(r$scaffold) == length(r$spans),
        sprintf("tokens=%d spans=%d", ntok(r$scaffold), length(r$spans)))
  }
  do.call(rbind, rows)
}

topics <- c("greet", "sexpr_install", "sexpr_render", "submit_proposal",
            "stress_multiline", "stress_multi", "stress_ambiguous", "stress_mixed", "stress_mloutput", "usermacro", "ifdef", "ifndef")

all <- do.call(rbind, lapply(topics, function(t)
  tryCatch(check_topic(t),
           error = function(e) data.frame(topic = t, section = "*", test = "topic",
                                          ok = FALSE, note = conditionMessage(e),
                                          stringsAsFactors = FALSE))))

cat("=== FAILURES ===\n")
fails <- all[!all$ok, , drop = FALSE]
if (nrow(fails) == 0) cat("none\n") else print(fails, row.names = FALSE)
cat(sprintf("\n=== %d / %d checks passed ===\n", sum(all$ok), nrow(all)))
