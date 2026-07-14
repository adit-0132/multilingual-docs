# Proof: {ISEXPR_*} placeholders need no author escaping in normal Rd help.
# Braces are Rd grouping syntax, so ordinary prose never emits a literal
# "{ISEXPR_n}". Only \{ISEXPR_n\} does -- escape such a literal as {{ISEXPR_n}}.
# Run top-to-bottom in RStudio (needs a current rhelpi18n) and read the output.

library(rhelpi18n)

# flatten a one-line \description and return its text
flatten <- function(body) {
  f <- tempfile(fileext = ".Rd")
  writeLines(c("\\name{t}", "\\title{t}", "\\description{", body, "}"), f)
  trimws(rhelpi18n:::rd_flatten(tools::parse_Rd(f))$description$original)
}
fill <- rhelpi18n:::match_and_fill        # fill(live, stored_scaffold, translation)

# 1. Prose braces are STRIPPED -> no token is produced -> nothing to escape.
cat("1. prose   {ISEXPR_0}   ->", flatten("Here: {ISEXPR_0}."), "\n")

# 2. Only \{..\} emits a LITERAL "{ISEXPR_0}" into the help text.
cat("2. escaped \\{ISEXPR_0\\} ->", flatten("Here: \\{ISEXPR_0\\}."), "\n")

# 3. Left raw in a scaffold, that literal is mis-read as a placeholder
#    -- the "X" from `live` is captured instead of the literal staying put:
cat("3. raw     {ISEXPR_0}   ->", fill("Here: X.", "Here: {ISEXPR_0}.", "Aqui: {ISEXPR_0}."), "\n")

# 4. Doubling the braces escapes it -> preserved as a literal, never filled:
cat("4. escaped {{ISEXPR_0}} ->", fill("Here: {ISEXPR_0}.", "Here: {{ISEXPR_0}}.", "Aqui: {{ISEXPR_0}}."), "\n")
