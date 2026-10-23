testthat::test_that("Census fields map to their named source columns", {
  benchmarks <- read_benchmarks(reference_dir)
  census <- benchmarks$census
  testthat::expect_equal(census$men_ny, c(46.8, 47.4, 47.5))
  testthat::expect_equal(100 - census$men_ny, c(53.2, 52.6, 52.5))
  testthat::expect_false(identical(census$men_ny, census$hispanic_ny))
})

testthat::test_that("historical missing markers remain missing", {
  benchmarks <- read_benchmarks(reference_dir)
  testthat::expect_true(is.numeric(benchmarks$ncvs_hispanic$rape_nh_other))
  testthat::expect_true(anyNA(benchmarks$ncvs_hispanic$rape_nh_other))
  testthat::expect_equal(nrow(benchmarks$ncvs_hispanic), 22L)
})

testthat::test_that("source files match the pinned manifest", {
  testthat::expect_silent(verify_sources())
})
