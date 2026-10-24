testthat::test_that("NYPD workbooks reproduce archived annual race/ethnicity shares", {
  counts <- read_nypd_race_counts(file.path(raw_dir, "nypd", "enforcement"))
  annual <- read_percent_table(file.path(reference_dir, "nypd", "enforcement_shares.csv"))
  testthat::expect_equal(nrow(counts), 192L)
  testthat::expect_equal(sort(unique(counts$year)), 2008:2015)
  for (i in seq_len(nrow(counts))) {
    row <- counts[i, ]
    column <- paste0(
      switch(row$offense,
        homicide = "homicides",
        rape = "rapes",
        robbery = "robberies",
        assault = "assaults"
      ),
      "_", row$group, "_", row$role
    )
    testthat::expect_equal(row$reported_pct, annual[[column]][annual$year == row$year])
  }
  ambiguous <- counts[
    counts$count_min != counts$count_max &
      counts$offense %in% c("homicide", "rape") & counts$group %in% c("black", "hispanic"),
  ]
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
  episodes <- read_episodes(episode_dir)
  sources <- read_benchmarks(raw_dir)
  pooled <- pooled_benchmarks(sources, episodes)
  nypd <- pooled[pooled$source == "nypd_enforcement", ]
  testthat::expect_equal(nrow(nypd), 8L)
  testthat::expect_true(all(nypd$first_year == 2008L & nypd$last_year == 2015L))
  testthat::expect_true(all(nypd$n_years == 8L))
  testthat::expect_equal(
    round(nypd$share_pct, 1), c(62.2, 39.5, 58.7, 51.3, 26.4, 37.3, 32.4, 34.9)
  )
})

testthat::test_that("NYPD female rape arrest reference uses checked annual counts", {
  counts <- read_nypd_rape_arrests(file.path(
    raw_dir, "nypd", "arrests", "rape_arrests.json"
  ))
  annual <- aggregate(n ~ year, data = counts, sum)
  report_totals <- vapply(2008:2015, function(year) {
    path <- file.path(
      raw_dir, "nypd", "enforcement", paste0("year=", year), "enforcement.xls"
    )
    sheet <- readxl::read_excel(
      path,
      sheet = "page 2", col_names = FALSE,
      col_types = "text", .name_repair = "minimal"
    )
    row <- which(trimws(sheet[[1]]) %in% c(
      "Total Victims/Suspects/Arrests", "Total Complaints/Arrests"
    ))
    as.integer(sheet[[4]][row])
  }, integer(1))
  testthat::expect_lte(max(abs(annual$n - report_totals)), 5L)
  testthat::expect_equal(sum(counts$n[counts$perp_sex == "F"]), 151L)
  testthat::expect_equal(pool_nypd_rape_arrests(counts, 2008:2015), 100 * 151 / 6643)

  episodes <- read_episodes(episode_dir)
  pooled <- pooled_benchmarks(read_benchmarks(raw_dir), episodes)
  row <- pooled[pooled$source == "nypd_arrests", ]
  testthat::expect_equal(nrow(row), 1L)
  testthat::expect_equal(row$share_pct, 100 * 151 / 6643)

  sources <- read_benchmarks(raw_dir)
  yearly <- estimate_shares(episodes)$yearly
  table <- annual_table(yearly, sources, benchmark_catalog(), "criminal", "female")
  reference <- sources$nypd_arrests
  testthat::expect_equal(
    table[["NYPD rape arrests"]],
    reference$rape_female_arrests[match(table$Year, reference$year)]
  )
})


testthat::test_that("homicide PDFs retain the published years, denominators, and suspect definitions", {
  counts <- extract_nypd_homicide_sex(file.path(raw_dir, "nypd", "homicide"))
  testthat::expect_equal(counts$total, c(536L, 285L, 515L, 373L, 419L, 290L))
  testthat::expect_equal(counts$reported_pct, c(17, 10, 20, 9, 16, 7))
  testthat::expect_equal(counts$role, c("victim", "arrestee", "victim", "suspect", "victim", "suspect"))
  testthat::expect_equal(counts$source_page, rep(c(5L, 9L), 3))
  victims <- pool_nypd_homicide_sex(counts, 2010:2012, "victim")
  suspects <- pool_nypd_homicide_sex(counts, 2010:2012, "suspect")
  testthat::expect_equal(unname(victims), 100 * c(261, 255, 267) / 1470)
  testthat::expect_equal(unname(suspects), 100 * c(53.5, 51, 56) / 663)
  annual <- nypd_homicide_annual_shares(counts)
  testthat::expect_true(is.na(annual$homicide_female_suspect[annual$year == 2010]))
  testthat::expect_equal(annual$homicide_female_arrestee[annual$year == 2010], 10)
})
