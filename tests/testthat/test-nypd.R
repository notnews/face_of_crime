testthat::test_that("NYPD workbooks reproduce archived annual race/ethnicity shares", {
  counts <- read_nypd_race_counts(file.path(reference_dir, "ny_enforcement"))
  annual <- read_percent_table(file.path(reference_dir, "ny_enforcement", "nyc_enforcement.csv"))
  testthat::expect_equal(nrow(counts), 64L)
  testthat::expect_equal(sort(unique(counts$year)), 2008:2015)
  for (i in seq_len(nrow(counts))) {
    row <- counts[i, ]
    column <- paste0(
      if (row$offense == "homicide") "homicides" else "rapes",
      "_", row$group, "_", row$role
    )
    testthat::expect_equal(row$reported_pct, annual[[column]][annual$year == row$year])
  }
  ambiguous <- counts[counts$count_min != counts$count_max, ]
  testthat::expect_equal(nrow(ambiguous), 1L)
  testthat::expect_equal(
    unlist(
      ambiguous[c("year", "offense", "role", "group", "count_min", "count_max", "known_total")],
      use.names = FALSE
    ),
    c("2012", "rape", "victim", "black", "438", "439", "1157")
  )
})

testthat::test_that("pooled NYPD comparisons cover the eight archived years", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  pooled <- pooled_benchmarks(sources, episodes)
  nypd <- pooled[pooled$source == "nyc", ]
  testthat::expect_equal(nrow(nypd), 8L)
  testthat::expect_true(all(nypd$first_year == 2008L & nypd$last_year == 2015L))
  testthat::expect_true(all(nypd$n_years == 8L))
  testthat::expect_equal(
    round(nypd$share_pct, 1), c(62.2, 39.5, 58.7, 51.3, 26.4, 37.3, 32.4, 34.9)
  )
})
