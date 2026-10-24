source("scripts/00_config.R")
manifest <- read_source_manifest()
requested <- commandArgs(trailingOnly = TRUE)
if (length(requested)) {
  stopifnot(all(requested %in% manifest$path))
  manifest <- manifest[manifest$path %in% requested, ]
}
options(timeout = 180, HTTPUserAgent = "Mozilla/5.0")
for (i in seq_len(nrow(manifest))) {
  item <- manifest[i, ]
  path <- project_file(item$path)
  if (file.exists(path)) {
    stopifnot(digest::digest(file = path, algo = "sha256") == item$sha256)
    next
  }
  temporary <- tempfile()
  utils::download.file(item$source_url, temporary, mode = "wb", method = "libcurl")
  if (digest::digest(file = temporary, algo = "sha256") != item$sha256) {
    unlink(temporary)
    stop("Downloaded bytes differ from the pinned source: ", item$path)
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(temporary, path, overwrite = FALSE))
  unlink(temporary)
}
