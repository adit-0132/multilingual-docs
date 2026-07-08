# Reads translations/*.yaml from the installed module and exposes them as
# `translations`, keyed by topic name (matches rhelpi18n's basename(file) lookup).
.rd_flat_read <- function(file) {
  rd_flat <- yaml::read_yaml(file)
  attr(rd_flat, "untranslatable") <- rd_flat[["untranslatable"]]
  rd_flat[["untranslatable"]] <- NULL
  rd_flat
}

translations <- local({
  dir   <- system.file("translations", package = "gsocproposal.es")
  files <- list.files(dir, pattern = "\\.yaml$", full.names = TRUE)
  tr    <- lapply(files, .rd_flat_read)
  names(tr) <- tools::file_path_sans_ext(basename(files))
  tr
})
