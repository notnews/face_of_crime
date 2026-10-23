source("scripts/00_config.R")
verify_sources()
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)

episodes <- read_episodes(raw_dir)
benchmarks <- read_benchmarks(reference_dir)
stopifnot(nrow(episodes) == 731L)
saveRDS(list(episodes = episodes, benchmarks = benchmarks), project_file("data", "build", "prepared_data.rds"))
utils::write.csv(episode_diagnostics(episodes), project_file("docs", "coding_discrepancies.csv"), row.names = FALSE)
