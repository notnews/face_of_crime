source(file.path(rprojroot::find_root(rprojroot::has_file("DESCRIPTION")), "R", "paths.R"))
source(project_file("R", "episodes.R"))
source(project_file("R", "ncvs.R"))
source(project_file("R", "ucr.R"))
source(project_file("R", "benchmarks.R"))
source(project_file("R", "analysis.R"))
source(project_file("R", "figures.R"))
source(project_file("R", "tables.R"))

verify_sources <- function(manifest_file = project_file("docs", "source_manifest.csv")) {
  manifest <- utils::read.csv(manifest_file, stringsAsFactors = FALSE)
  actual <- vapply(manifest$path, function(path) {
    digest::digest(file = project_file(path), algo = "sha256")
  }, character(1))
  if (!identical(unname(actual), manifest$sha256)) {
    stop("Source file hash differs from docs/source_manifest.csv")
  }
  invisible(TRUE)
}
