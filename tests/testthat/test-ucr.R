testthat::test_that("UCR workbook counts reproduce archived arrest percentages", {
  counts <- read_ucr_arrest_counts(project_file("data", "raw", "ucr", "arrests.xlsx"))
  annual <- ucr_annual_shares(counts)
  archived <- read_percent_table(project_file("data", "reference", "ucr", "arrest_shares.csv"))
  testthat::expect_equal(counts$year, rep(1995:2015, each = 5L))
  testthat::expect_equal(annual$year, archived$year)
  for (column in intersect(names(annual), names(archived))) {
    testthat::expect_lt(max(abs(annual[[column]] - archived[[column]])), 0.051)
  }
  archived_ethnicity <- read_percent_table(project_file(
    "data", "reference", "ucr", "arrest_ethnicity_shares.csv"
  ))
  for (offense in c("all", "homicide", "rape")) {
    column <- switch(offense,
      all = "all_crime_perc_hispanic",
      homicide = "homicides_perc_hispanic",
      rape = "rape_perc_hispanic"
    )
    part <- counts[counts$offense == offense & counts$year >= 2013, ]
    expected <- archived_ethnicity[[column]][archived_ethnicity$year >= 2013]
    testthat::expect_lt(max(abs(100 * part$hispanic / part$ethnicity_total - expected)), 0.051)
  }
})

testthat::test_that("murder victim count denominators include unknown classifications", {
  counts <- read_ucr_murder_victim_counts(project_file("data", "raw", "ucr", "homicide_victims.xlsx"))
  annual <- murder_victim_annual_shares(counts)
  archived <- read_percent_table(project_file("data", "reference", "ucr", "homicide_victim_shares.csv"))
  testthat::expect_equal(annual$year, archived$year)
  testthat::expect_lt(max(abs(annual$murder_victim_black - archived$murder_victim_black)), 0.51)
  testthat::expect_lt(max(abs(annual$murder_victim_men - archived$murder_victim_men)), 0.8)
  testthat::expect_equal(
    pool_count_share(counts, 1995, "female"),
    100 * 4654 / 20043
  )
})
