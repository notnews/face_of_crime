project_root <- rprojroot::find_root(rprojroot::has_file("DESCRIPTION"))

project_file <- function(...) {
  file.path(project_root, ...)
}

raw_dir <- project_file("data", "raw")
episode_dir <- file.path(raw_dir, "episodes")
reference_dir <- project_file("data", "reference")
extracted_dir <- project_file("data", "extracted")
build_dir <- project_file("data", "build")
figure_dir <- project_file("figs")
table_dir <- project_file("tabs")
