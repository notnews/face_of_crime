source("scripts/00_config.R")
results <- readRDS(project_file("data", "build", "results.rds"))
source_tables <- readRDS(project_file("data", "build", "prepared_data.rds"))$benchmarks
write_figures(results$shares$aggregate, results$shares$yearly, results$benchmarks, source_tables, figure_dir)
