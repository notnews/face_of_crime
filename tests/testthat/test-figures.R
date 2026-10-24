testthat::test_that("aggregate plots use only all-episode show shares", {
  episodes <- read_episodes(raw_dir)
  shares <- estimate_shares(episodes)$aggregate
  benchmarks <- summarise_benchmarks(read_benchmarks(reference_dir))

  testthat::expect_true(all(shares$crime_group == "all"))
  for (role in c("victim", "criminal")) {
    for (group in c("female", "black", "hispanic")) {
      plot <- plot_aggregate_share(shares, benchmarks, role, group)
      show <- plot$data[plot$data$comparison == "Coded Episodes", ]
      expected <- shares[shares$role == role & shares$group == group, ]
      testthat::expect_equal(nrow(show), 3L)
      testthat::expect_equal(as.character(show$entity), expected$series)
      testthat::expect_equal(show$share_pct, expected$share_pct)
    }
  }
})

testthat::test_that("NCVS rape point is a victimization share", {
  sources <- read_benchmarks(reference_dir)
  benchmarks <- summarise_benchmarks(sources)
  shares <- estimate_shares(read_episodes(raw_dir))$aggregate
  plot <- plot_aggregate_share(shares, benchmarks, "victim", "female")
  rape <- plot$data[grepl("NCVS rape/sexual assault", plot$data$entity, fixed = TRUE), ]

  testthat::expect_equal(nrow(rape), 1L)
  testthat::expect_match(as.character(rape$entity), "victimizations")
  testthat::expect_equal(rape$share_pct, mean(100 - sources$ncvs$rape_sexual_assault_male))
  testthat::expect_equal(round(rape$share_pct, 1), 89.7)
})

testthat::test_that("manuscript NCVS race values match plotted years", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  shares <- estimate_shares(episodes)$aggregate
  benchmarks <- summarise_benchmarks(sources)
  path <- tempfile(fileext = ".tex")
  write_macros(shares, benchmarks, episodes, sources, path)
  macros <- readLines(path)

  for (pair in list(
    c("NcvsSeriousBlackPct", "serious_violent_victimization_nh_black"),
    c("NcvsRapeBlackPct", "rape_nh_black"),
    c("NcvsAssaultBlackPct", "aggravated_assault_nh_black")
  )) {
    expected <- sprintf("\\newcommand{\\%s}{%.1f}", pair[1], mean(sources$ncvs_hispanic[[pair[2]]]))
    testthat::expect_true(expected %in% macros)
  }
})
