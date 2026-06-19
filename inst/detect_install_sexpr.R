# Source<->installed diff: detect install/build-stage \Sexpr spans in compiled help,
# WITHOUT editing the package's .Rd files.
#
# Why: rhelpi18n keys each section's translation on exact-string equality of the
# flattened `original`. An install-stage \Sexpr bakes a *volatile* value (e.g.
# format(Sys.time())) into that string, so the match breaks every install and the
# section silently reverts to the source language. This detector recovers exactly
# which spans of the installed text came from install/build Sexpr, replaces them
# with stable {ISEXPR_i} tokens, and fingerprints the resulting scaffold -> a key
# that is STABLE across installs.
#
# How: we already have both trees from one source parse.
#   - source parse        -> install/build \Sexpr are LIVE nodes
#   - prepare_Rd(...)      -> reproduces the installed .rdb (build+install baked)
# Flatten both with the SAME rhelpi18n:::rd_flatten rhelpi18n uses at help time;
# the two `original` strings differ ONLY where an install/build Sexpr sat. Diff them.
#
#   source("multilingual-docs/inst/detect_install_sexpr.R")
#   print_install_sexpr(detect_install_sexpr("greet"))

# ---- flatten a section to the exact string rhelpi18n compares -----------------
.flatten_original <- function(rd) {
  flat <- rhelpi18n:::rd_flatten(rd)
  out <- list()
  for (sec in names(flat)) {
    el <- flat[[sec]]
    if (is.list(el) && !is.null(el$original)) out[[sec]] <- el$original
  }
  out
}

# Any \Sexpr[...]{...} whose option is NOT stage=render is install/build/default-install.
.INSTALL_SEXPR_RE <- "\\\\Sexpr\\[[^]]*\\]\\{[^}]*\\}"

.is_render <- function(sexpr_str) grepl("stage=render", sexpr_str, fixed = TRUE)

# Pull the install/build \Sexpr substrings (in order) from a source `original`.
.find_install_sexprs <- function(src_o) {
  m <- gregexpr(.INSTALL_SEXPR_RE, src_o, perl = TRUE)[[1]]
  if (m[1] == -1) return(character(0))
  hits <- regmatches(src_o, gregexpr(.INSTALL_SEXPR_RE, src_o, perl = TRUE))[[1]]
  hits[!vapply(hits, .is_render, logical(1))]
}

# Extract just the R code from a \Sexpr[opt]{code} string.
.sexpr_code   <- function(s) trimws(sub("^\\\\Sexpr\\[[^]]*\\]\\{(.*)\\}$", "\\1", s))
.sexpr_option <- function(s) sub("^\\\\Sexpr\\[([^]]*)\\]\\{.*$", "\\1", s)

# Split a string on a set of literal markers, returning the static anchors between.
.split_on <- function(s, markers) {
  anchors <- character(0)
  rest <- s
  for (mk in markers) {
    p <- regexpr(mk, rest, fixed = TRUE)
    if (p == -1) stop("marker not found while splitting source original")
    anchors <- c(anchors, substr(rest, 1, p - 1))
    rest <- substr(rest, p + nchar(mk), nchar(rest))
  }
  c(anchors, rest)                     # n markers -> n+1 anchors
}

# Locate anchors sequentially in `inst_o`; the gaps between them are baked values.
.align_anchors <- function(anchors, inst_o) {
  n_spans <- length(anchors) - 1L
  baked <- character(n_spans)
  pos <- 1L
  cur <- inst_o
  consume <- function(anchor, s) {
    if (nchar(anchor) == 0) return(list(before = "", rest = s))
    p <- regexpr(anchor, s, fixed = TRUE)
    if (p == -1) stop("anchor not found while aligning installed original")
    list(before = substr(s, 1, p - 1), rest = substr(s, p + nchar(anchor), nchar(s)))
  }
  # first anchor sits at the start
  step <- consume(anchors[1], cur); cur <- step$rest
  for (i in seq_len(n_spans)) {
    nxt <- consume(anchors[i + 1L], cur)
    baked[i] <- nxt$before          # text between anchor i and i+1 = baked value
    cur <- nxt$rest
  }
  baked
}

#' Detect install/build \Sexpr spans for one help topic.
#' @return named list per translatable section: {original, scaffold, spans, fingerprint}
detect_install_sexpr <- function(topic,
                                 src_dir = "~/Projects/0-multilingual/multilingual-docs",
                                 defines = .Platform$OS.type) {
  src_dir <- path.expand(src_dir)
  macros  <- tools::loadPkgRdMacros(src_dir)
  src_rd  <- tools::parse_Rd(file.path(src_dir, "man", paste0(topic, ".Rd")), macros = macros)
  baked   <- tools:::prepare_Rd(src_rd, defines = defines, stages = c("build", "install"))

  src_orig  <- .flatten_original(src_rd)
  inst_orig <- .flatten_original(baked)

  out <- list()
  for (sec in names(inst_orig)) {
    inst_o <- inst_orig[[sec]]
    src_o  <- src_orig[[sec]]
    markers <- if (is.null(src_o)) character(0) else .find_install_sexprs(src_o)

    if (length(markers) == 0) {
      out[[sec]] <- list(original = inst_o, scaffold = inst_o,
                         spans = list(), fingerprint = inst_o)
      next
    }
    anchors <- .split_on(src_o, markers)
    baked_vals <- .align_anchors(anchors, inst_o)

    # rebuild scaffold from the same anchors, install spans -> {ISEXPR_i}
    scaffold <- anchors[1]
    spans <- vector("list", length(markers))
    for (i in seq_along(markers)) {
      scaffold <- paste0(scaffold, "{ISEXPR_", i - 1L, "}", anchors[i + 1L])
      spans[[i]] <- list(i = i - 1L, source_code = .sexpr_code(markers[i]),
                         option = .sexpr_option(markers[i]), baked_value = baked_vals[i])
    }
    out[[sec]] <- list(original = inst_o, scaffold = scaffold,
                       spans = spans, fingerprint = scaffold)
  }
  out
}

#' Pretty-print a detect_install_sexpr() result.
print_install_sexpr <- function(res) {
  for (sec in names(res)) {
    r <- res[[sec]]
    cat("==== ", sec, " ====\n", sep = "")
    cat("  scaffold (fingerprint): ", gsub("\n", " ", r$scaffold), "\n", sep = "")
    if (length(r$spans) == 0) {
      cat("  install spans: none\n\n")
    } else {
      for (s in r$spans) {
        cat(sprintf("  {ISEXPR_%d}  code=%s  [%s]  baked=%s\n",
                    s$i, s$source_code, s$option, dQuote(s$baked_value)))
      }
      cat("\n")
    }
  }
  invisible(res)
}
