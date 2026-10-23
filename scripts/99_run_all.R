stages <- c("01_prepare_data.R", "02_estimate.R", "03_figures.R", "04_tables.R")
for (stage in stages) {
  status <- system2(file.path(R.home("bin"), "Rscript"), file.path("scripts", stage))
  if (status != 0L) stop("Analysis stage failed: ", stage)
}
