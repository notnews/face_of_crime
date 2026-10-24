testthat::test_that("main figures show three coded series and one dot per reference", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  shares <- estimate_shares(episodes)$aggregate
  benchmarks <- pooled_benchmarks(sources, episodes)

  for (role in c("victim", "criminal")) {
    for (group in c("female", "black", "hispanic")) {
      plot <- plot_aggregate_share(shares, benchmarks, role, group)
      show <- plot$data[as.character(plot$data$entity) == "Coded Episodes", ]
      reference <- plot$data[as.character(plot$data$legend) == "Historical Reference", ]
      expected <- shares[shares$role == role & shares$group == group, ]
      expected_reference <- benchmarks[benchmarks$role == role & benchmarks$group == group, ]
      testthat::expect_equal(nrow(show), 3L)
      testthat::expect_equal(as.character(show$legend), expected$series)
      testthat::expect_equal(show$share_pct, expected$share_pct)
      testthat::expect_equal(nrow(reference), nrow(expected_reference))
      testthat::expect_false(anyDuplicated(as.character(reference$entity)) > 0L)
      testthat::expect_equal(reference$share_pct, expected_reference$share_pct)
    }
  }
})

testthat::test_that("common reference pools only years with a coded episode", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  benchmarks <- pooled_benchmarks(sources, episodes)
  black <- benchmarks[
    benchmarks$source == "ncvs_hispanic" &
      benchmarks$column == "serious_violent_victimization_nh_black",
  ]
  expected <- ncvs_share(sources$ncvs_records, 1999:2014, "serious_violent", "victim_nh_black")
  testthat::expect_equal(nrow(black), 1L)
  testthat::expect_equal(black$share_pct, expected$share_pct)
  testthat::expect_equal(c(black$first_year, black$last_year, black$n_years), c(1999, 2014, 16))

  female <- benchmarks[benchmarks$column == "serious_violent_offender_female_only", ]
  testthat::expect_equal(nrow(female), 1L)
  testthat::expect_equal(
    female$share_pct,
    ncvs_share(sources$ncvs_records, 1999:2014, "serious_violent", "offender_female_only")$share_pct
  )

  ucr <- benchmarks[benchmarks$source == "ucr" & benchmarks$column == "violent_crime_perc_black", ]
  counts <- sources$ucr_counts[sources$ucr_counts$offense == "violent", ]
  testthat::expect_equal(ucr$share_pct, pool_count_share(counts, 1999:2015, "black"))
  testthat::expect_equal(ucr$n_years, 17L)
})

testthat::test_that("manuscript macro matches the single plotted NCVS reference", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  shares <- estimate_shares(episodes)$aggregate
  benchmarks <- pooled_benchmarks(sources, episodes)
  path <- tempfile(fileext = ".tex")
  write_macros(shares, benchmarks, episodes, path)
  macros <- readLines(path)
  value <- benchmarks$share_pct[
    benchmarks$source == "ncvs_hispanic" &
      benchmarks$column == "serious_violent_victimization_nh_black"
  ]
  testthat::expect_true(
    sprintf("\\newcommand{\\NcvsSeriousBlackPct}{%.1f}", value) %in% macros
  )
})
