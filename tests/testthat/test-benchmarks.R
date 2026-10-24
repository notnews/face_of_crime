testthat::test_that("Census fields map to their named source columns", {
  benchmarks <- read_benchmarks(reference_dir)
  census <- benchmarks$census
  testthat::expect_equal(census$men_ny, c(46.8, 47.4, 47.5))
  testthat::expect_equal(100 - census$men_ny, c(53.2, 52.6, 52.5))
  testthat::expect_false(identical(census$men_ny, census$hispanic_ny))
})

testthat::test_that("historical missing markers remain missing", {
  legacy <- read_percent_table(file.path(reference_dir, "ncvs", "ncvs_hispanic.csv"))
  rebuilt <- read_benchmarks(reference_dir)$ncvs_hispanic
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
  testthat::expect_true(all(rows$source == "ncvs_hispanic"))
  testthat::expect_equal(
    rows$column,
    c("serious_violent_victimization_nh_black", "rape_nh_black", "aggravated_assault_nh_black")
  )
})

testthat::test_that("source files match the pinned manifest", {
  testthat::expect_silent(verify_sources())
})
