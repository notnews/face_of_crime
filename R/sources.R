read_source_manifest <- function() {
  utils::read.csv(project_file("data", "source_manifest.csv"), stringsAsFactors = FALSE)
}

verify_sources <- function() {
  manifest <- read_source_manifest()
  paths <- unlist(lapply(c(raw_dir, reference_dir), list.files, recursive = TRUE, full.names = TRUE))
  relative <- substring(paths, nchar(project_root) + 2L)
  stopifnot(!anyDuplicated(manifest$path), setequal(relative, manifest$path))
  actual <- vapply(manifest$path, function(path) {
    digest::digest(file = project_file(path), algo = "sha256")
  }, character(1))
  if (!identical(unname(actual), manifest$sha256)) {
    stop("Source file hash differs from data/source_manifest.csv")
  }
  invisible(TRUE)
}

read_census_shares <- function(path) {
  census <- as.data.frame(readxl::read_excel(path, sheet = "Sheet1", .name_repair = "minimal"))
  stopifnot(ncol(census) == 7L, identical(as.integer(census[[1]]), c(1990L, 2000L, 2010L)))
  names(census) <- c("year", "white_us", "black_us", "men_us", "white_ny", "black_ny", "men_ny")
  census$year <- as.integer(census$year)
  census
}

write_extracted_data <- function(episodes, benchmarks, directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  tables <- c(list(episodes = episodes), benchmarks)
  for (name in names(tables)) {
    utils::write.csv(tables[[name]], file.path(directory, paste0(name, ".csv")), row.names = FALSE, na = "")
  }
}
