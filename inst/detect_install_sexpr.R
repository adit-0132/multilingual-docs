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
# Install/build \Sexpr nodes are collected from the PARSE TREE (so multi-line code
# and nested braces are handled by the parser, not a fragile regex); each node's
# exact deparse (rhelpi18n:::to_text) is then located by fixed-string search in the
# flattened source, and the matching gap in the baked flatten is its baked value.
#
# Sentinel note: {ISEXPR_i} is collision-safe in practice because Rd strips literal
# braces from prose (a doc that writes "{ISEXPR_0}" flattens to "ISEXPR_0"), so a
# real token never clashes with authored text.
#
#   source("multilingual-docs/inst/detect_install_sexpr.R")
#   print_install_sexpr(detect_install_sexpr("greet"))

`%||%` <- function(a, b) if (is.null(a)) b else a

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

# ---- collect dynamic markers from the PARSE TREE ------------------------------
# Returns records {marker, kind, option, code} for every dynamic node, in document
# order. Dynamic = a non-render \Sexpr (install / build / default-install) or a
# #ifdef / #ifndef block. `marker` is the node's exact deparse (== how it appears
# in the flattened source), so a later fixed-string search finds it regardless of
# newlines or nested braces. Dynamic nodes are opaque: we do NOT recurse into them.
.collect_sexpr_markers <- function(node, acc = list()) {
  tag <- attr(node, "Rd_tag")
  if (identical(tag, "\\Sexpr") &&
      !isTRUE(grepl("stage=render", attr(node, "Rd_option") %||% ""))) {
    acc[[length(acc) + 1L]] <- list(
      marker = rhelpi18n:::to_text(node), kind = "sexpr",
      option = attr(node, "Rd_option") %||% "",
      code   = trimws(paste(rapply(node, function(x) as.character(x), how = "unlist"),
                            collapse = "")))
    return(acc)
  }
  if (!is.null(tag) && tag %in% c("#ifdef", "#ifndef")) {
    acc[[length(acc) + 1L]] <- list(
      marker = rhelpi18n:::to_text(node), kind = "ifdef", option = tag,
      code   = trimws(paste(rapply(node, function(x) as.character(x), how = "unlist"),
                            collapse = "")))
    return(acc)
  }
  if (is.list(node)) for (child in node) acc <- .collect_sexpr_markers(child, acc)
  acc
}

# Records whose deparse occurs in `src_o`, ordered by position in `src_o`.
.markers_in <- function(src_o, records) {
  hit <- Filter(function(r) grepl(r$marker, src_o, fixed = TRUE), records)
  if (length(hit) == 0) return(hit)
  pos <- vapply(hit, function(r) regexpr(r$marker, src_o, fixed = TRUE)[[1]], numeric(1))
  hit[order(pos)]
}

# Split `s` on a set of literal markers, returning the static anchors between.
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
  cur <- inst_o
  consume <- function(anchor, s) {
    if (nchar(anchor) == 0) return(list(before = "", rest = s))
    p <- regexpr(anchor, s, fixed = TRUE)
    if (p == -1) stop("anchor not found while aligning installed original")
    list(before = substr(s, 1, p - 1), rest = substr(s, p + nchar(anchor), nchar(s)))
  }
  step <- consume(anchors[1], cur); cur <- step$rest
  for (i in seq_len(n_spans)) {
    nxt <- consume(anchors[i + 1L], cur)
    baked[i] <- nxt$before
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

  records   <- .collect_sexpr_markers(src_rd)
  src_orig  <- .flatten_original(src_rd)
  inst_orig <- .flatten_original(baked)

  out <- list()
  for (sec in names(inst_orig)) {
    inst_o <- inst_orig[[sec]]
    src_o  <- src_orig[[sec]]
    recs   <- if (is.null(src_o)) list() else .markers_in(src_o, records)

    if (length(recs) == 0) {
      out[[sec]] <- list(original = inst_o, scaffold = inst_o,
                         spans = list(), fingerprint = inst_o)
      next
    }
    markers    <- vapply(recs, function(r) r$marker, character(1))
    anchors    <- .split_on(src_o, markers)
    baked_vals <- .align_anchors(anchors, inst_o)

    scaffold <- anchors[1]
    spans <- vector("list", length(recs))
    for (i in seq_along(recs)) {
      scaffold <- paste0(scaffold, "{ISEXPR_", i - 1L, "}", anchors[i + 1L])
      spans[[i]] <- list(i = i - 1L, kind = recs[[i]]$kind, source_code = recs[[i]]$code,
                         option = recs[[i]]$option, baked_value = baked_vals[i])
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
                    s$i, gsub("\n", " ", s$source_code), s$option, dQuote(s$baked_value)))
      }
      cat("\n")
    }
  }
  invisible(res)
}
