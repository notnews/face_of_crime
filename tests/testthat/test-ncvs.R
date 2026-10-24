testthat::test_that("BJS records reproduce historical NCVS annual shares", {
  records <- read_ncvs_records(file.path(raw_dir, "ncvs", "personal_victimizations.csv"))
  annual <- ncvs_annual_shares(records)

  for (source in c("ncvs", "ncvs_race_ethnicity")) {
    legacy <- read_percent_table(file.path(
      reference_dir, "ncvs",
      if (source == "ncvs") "annual_shares.csv" else "annual_race_ethnicity_shares.csv"
    ))
    names(legacy) <- sub("^assault_", "simple_assault_", names(legacy))
    names(legacy)[names(legacy) == "violent_cictimization_nh_other"] <-
      "violent_victimization_nh_other"
    rebuilt <- annual[[source]]
    testthat::expect_true(all(names(legacy) %in% names(rebuilt)))
    testthat::expect_equal(rebuilt$year, legacy$year)
    difference <- abs(as.matrix(rebuilt[names(legacy)[-1]]) - as.matrix(legacy[-1]))
    testthat::expect_lt(max(difference, na.rm = TRUE), 0.051)
  }
})

testthat::test_that("pooled NCVS shares use victimization weights", {
  records <- read_ncvs_records(file.path(raw_dir, "ncvs", "personal_victimizations.csv"))
  black_2010 <- ncvs_share(records, 2010L, "serious_violent", "victim_nh_black")
  testthat::expect_equal(round(black_2010$share_pct, 1), 18.6)

  two_years <- data.frame(
    year = c(2001L, 2002L), offense = c(1L, 1L),
    victim_race_ethnicity = c(1L, 2L), weight = c(1, 9)
  )
  pooled <- ncvs_share(two_years, 2001:2002, "rape_sexual_assault", "victim_nh_black")
  testthat::expect_equal(pooled$numerator, 9)
  testthat::expect_equal(pooled$denominator, 10)
  testthat::expect_equal(pooled$share_pct, 90)
})

testthat::test_that("NCVS offender sex describes known-sex incidents", {
  records <- read_ncvs_records(file.path(raw_dir, "ncvs", "personal_victimizations.csv"))
  female <- ncvs_share(records, 2010L, "serious_violent", "offender_female_only")
  all_incidents <- ncvs_share(records, 2010L, "serious_violent", "victim_female")
  testthat::expect_gt(all_incidents$denominator, female$denominator)
  testthat::expect_gt(female$share_pct, 0)
  testthat::expect_lt(female$share_pct, 100)
  annual <- ncvs_annual_shares(records)$ncvs
  testthat::expect_equal(
    annual$serious_violent_offender_female_only[annual$year == 2010],
    female$share_pct
  )
})
