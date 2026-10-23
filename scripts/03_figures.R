source("scripts/00_config.R")
results <- readRDS(project_file("data", "build", "results.rds"))
write_figures(results$shares$aggregate, results$shares$yearly, results$benchmarks, figure_dir)
