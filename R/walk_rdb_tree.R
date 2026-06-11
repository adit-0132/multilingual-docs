#' Walk the compiled Rd_db tree of a help topic
#'
#' Pretty-prints the parse tree of a help topic as stored in the *installed*
#' `.rdb` database (via [tools::Rd_db()]), one node per line, indented by depth.
#' Unlike walking the source `.Rd` with [tools::parse_Rd()], this shows the
#' post-install tree: build- and install-stage `Sexpr` are baked to plain text,
#' `#ifdef` blocks are resolved, render-stage `Sexpr` stay live (with their
#' `Rd_option`), and user macros keep a `USERMACRO` trace.
#'
#' @param topic Help topic to inspect, given **unquoted**
#'   (e.g. `walk_rdb_tree(sexpr_render)`) or as a string
#'   (`walk_rdb_tree("sexpr_render")`). A trailing `.Rd` is optional.
#' @param package Installed package to read from. Defaults to `"gsocproposal"`.
#'
#' @return Invisibly, the `Rd` object for `topic`; called for the side effect of
#'   printing the tree.
#'
#' @examples
#' walk_rdb_tree(sexpr_render)
#' walk_rdb_tree(ifdef)
#'
#' @export
walk_rdb_tree <- function(topic, package = "gsocproposal") {
  topic <- as.character(substitute(topic))
  db    <- tools::Rd_db(package)
  key   <- if (topic %in% names(db)) topic else paste0(topic, ".Rd")
  if (!key %in% names(db)) {
    stop("No help topic '", topic, "' in package '", package, "'.\n",
         "Available: ", paste(sub("\\.Rd$", "", names(db)), collapse = ", "),
         call. = FALSE)
  }
  cat("### COMPILED rd_db tree:", key, "\n")
  walk_rd(db[[key]])
  invisible(db[[key]])
}

# Internal: recursively print one Rd node and its children.
walk_rd <- function(node, depth = 0) {
  tag <- attr(node, "Rd_tag")
  if (is.null(tag)) tag <- "(root)"

  prefix <- strrep("  ", depth)

  # Leaf nodes (character vectors): show content (+ macro trace if present).
  if (is.character(node)) {
    macro   <- attr(node, "macro")
    tagline <- if (!is.null(macro) && is.character(macro)) {
      sprintf("%s [macro: %s]", tag, macro)
    } else tag
    txt <- paste(node, collapse = "")
    txt <- gsub("\n", "\\\\n", txt)
    if (nchar(txt) > 80) txt <- paste0(substr(txt, 1, 77), "...")
    cat(sprintf("%s%s: %s\n", prefix, tagline, txt))
    return(invisible(NULL))
  }

  # List nodes: show tag, Rd_option (Sexpr stage/results), and macro trace.
  option <- attr(node, "Rd_option")
  macro  <- attr(node, "macro")
  extra <- ""
  if (!is.null(option)) {
    opt_text <- if (is.character(option)) option else paste(unlist(option), collapse = "")
    extra <- paste0(extra, sprintf(" [option: %s]", opt_text))
  }
  if (!is.null(macro) && is.character(macro)) {
    extra <- paste0(extra, sprintf(" [macro: %s]", macro))
  }
  cat(sprintf("%s%s%s\n", prefix, tag, extra))

  for (child in node) walk_rd(child, depth + 1)
}
