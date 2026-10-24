source("scripts/00_config.R")
prepared <- readRDS(project_file("data", "build", "prepared_data.rds"))
shares <- estimate_shares(prepared$episodes)
benchmarks <- matched_benchmarks(prepared$benchmarks, prepared$episodes)

saveRDS(
  list(shares = shares, benchmarks = benchmarks),
  project_file("data", "build", "results.rds")
)
utils::write.csv(shares$aggregate, file.path(table_dir, "aggregate_shares.csv"), row.names = FALSE, na = "")
utils::write.csv(shares$yearly, file.path(table_dir, "yearly_shares.csv"), row.names = FALSE, na = "")
utils::write.csv(benchmarks, file.path(table_dir, "benchmarks.csv"), row.names = FALSE, na = "")
