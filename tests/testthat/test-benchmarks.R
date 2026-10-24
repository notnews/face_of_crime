testthat::test_that("Census fields map to their named source columns", {
  benchmarks <- read_benchmarks(raw_dir)
  census <- benchmarks$census
  testthat::expect_equal(census$men_ny, c(46.8, 47.4, 47.5))
  testthat::expect_equal(100 - census$men_ny, c(53.2, 52.6, 52.5))
  archived <- read_percent_table(file.path(reference_dir, "census", "population.csv"))
  expected <- archived[c(
    "year", "perc_whiteus", "perc_blackus", "perc_menus",
    "perc_whiteny", "perc_blackny", "perc_menny"
  )]
  names(expected) <- names(census)
  testthat::expect_equal(census, expected)
})

testthat::test_that("historical missing markers remain missing", {
  legacy <- read_percent_table(file.path(reference_dir, "ncvs", "annual_race_ethnicity_shares.csv"))
  rebuilt <- read_benchmarks(raw_dir)$ncvs_race_ethnicity
  testthat::expect_true(anyNA(legacy$rape_nh_other))
  testthat::expect_false(anyNA(rebuilt$rape_nh_other))
  testthat::expect_equal(nrow(rebuilt), 22L)
})

testthat::test_that("NCVS Black references exclude Hispanic respondents", {
  catalog <- benchmark_catalog()
  rows <- catalog[
    catalog$role == "victim" & catalog$group == "black" & grepl("^NCVS", catalog$label),
  ]
  testthat::expect_equal(nrow(rows), 3L)
  testthat::expect_true(all(rows$source == "ncvs_race_ethnicity"))
  testthat::expect_equal(
    rows$column,
    c("serious_violent_victimization_nh_black", "rape_nh_black", "aggravated_assault_nh_black")
  )
})

testthat::test_that("source files match the pinned manifest", {
  testthat::expect_silent(verify_sources())
})

testthat::test_that("reference inventory retains estimates and separates incompatible homicide populations", {
  episodes <- read_episodes(episode_dir)
  sources <- read_benchmarks(raw_dir)
  pooled <- pooled_benchmarks(sources, episodes)
  inventory <- reference_inventory(pooled, sources, episodes)
  testthat::expect_equal(inventory[seq_len(nrow(pooled)), names(pooled)[1:9]], pooled[, 1:9])
  testthat::expect_equal(nrow(inventory), nrow(pooled) + 11L)
  homicide <- inventory[inventory$source == "nypd_homicide", ]
  testthat::expect_equal(homicide$first_year, c(2010L, 2011L, 2010L))
  testthat::expect_equal(homicide$last_year, c(2012L, 2012L, 2010L))
  rounded <- inventory[!is.na(inventory$rounding_lower_pct), ]
  testthat::expect_true(all(rounded$rounding_lower_pct <= rounded$share_pct))
  testthat::expect_true(all(rounded$rounding_upper_pct >= rounded$share_pct))
})
