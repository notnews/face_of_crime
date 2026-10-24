testthat::test_that("main figure dots use each show's broadcast-year reference counts", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  shares <- estimate_shares(episodes)$aggregate
  benchmarks <- matched_benchmarks(sources, episodes)

  for (role in c("victim", "criminal")) {
    for (group in c("female", "black", "hispanic")) {
      plot <- plot_aggregate_share(shares, benchmarks, role, group)
      show <- plot$data[as.character(plot$data$entity) == "Coded Episodes", ]
      expected <- shares[shares$role == role & shares$group == group, ]
      testthat::expect_equal(nrow(show), 3L)
      testthat::expect_equal(as.character(show$series), expected$series)
      testthat::expect_equal(show$share_pct, expected$share_pct)
    }
  }

  ci <- benchmarks[
    benchmarks$series == "Criminal Intent" & benchmarks$source == "ncvs_hispanic" &
      benchmarks$column == "serious_violent_victimization_nh_black",
  ]
  expected <- ncvs_share(sources$ncvs_records, 2001:2011, "serious_violent", "victim_nh_black")
  testthat::expect_equal(ci$share_pct, expected$share_pct)
  testthat::expect_equal(ci$n_years, 11L)
  testthat::expect_gt(ci$share_pct, 19)
  testthat::expect_lt(ci$share_pct, 21)
})

testthat::test_that("female offender NCVS dot is an incident share", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  benchmarks <- matched_benchmarks(sources, episodes)
  female <- benchmarks[benchmarks$column == "serious_violent_offender_female_only", ]
  testthat::expect_equal(nrow(female), 3L)
  testthat::expect_true(all(female$share_pct > 12 & female$share_pct < 14))
  testthat::expect_match(female$label[1], "female-only offender")
  testthat::expect_equal(
    female$share_pct[female$series == "Criminal Intent"],
    ncvs_share(sources$ncvs_records, 2001:2011, "serious_violent", "offender_female_only")$share_pct
  )
})

testthat::test_that("manuscript macros bracket plotted NCVS values", {
  episodes <- read_episodes(raw_dir)
  sources <- read_benchmarks(reference_dir)
  shares <- estimate_shares(episodes)$aggregate
  benchmarks <- matched_benchmarks(sources, episodes)
  path <- tempfile(fileext = ".tex")
  write_macros(shares, benchmarks, episodes, path)
  macros <- readLines(path)

  values <- benchmarks$share_pct[
    benchmarks$source == "ncvs_hispanic" &
      benchmarks$column == "serious_violent_victimization_nh_black"
  ]
  testthat::expect_true(
    sprintf("\\newcommand{\\NcvsSeriousBlackLowPct}{%.1f}", min(values)) %in% macros
  )
  testthat::expect_true(
    sprintf("\\newcommand{\\NcvsSeriousBlackHighPct}{%.1f}", max(values)) %in% macros
  )
})
