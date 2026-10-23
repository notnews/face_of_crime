testthat::test_that("coded categories parse counts without swallowing ambiguous labels", {
  testthat::expect_equal(
    parse_categories("2 black,  1 asian, 2 unknown", c("black", "asian")),
    c(black = 2L, asian = 1L)
  )
  testthat::expect_equal(parse_categories("1 white, 1hispanic", c("white", "hispanic")), c(white = 1L, hispanic = 1L))
  testthat::expect_equal(parse_categories("Female*", c("male", "female")), c(male = 0L, female = 0L))
  testthat::expect_equal(parse_categories("3 females, 1 male", c("male", "female")), c(male = 1L, female = 3L))
})

testthat::test_that("episode inputs conserve their distinct rows", {
  episodes <- read_episodes(raw_dir)
  testthat::expect_equal(nrow(episodes), 731L)
  counts <- as.integer(table(episodes$series)[c("Criminal Intent", "Original", "SVU")])
  testthat::expect_equal(counts, c(194L, 151L, 386L))
  testthat::expect_equal(sum(episodes$is_murder | episodes$is_rape | episodes$is_assault), 661L)
  testthat::expect_equal(sum(duplicated(episodes[c("series", "season", "episode")])), 1L)
  testthat::expect_equal(nrow(episode_diagnostics(episodes)), 12L)
})

testthat::test_that("the transposed Mushrooms labels are assigned to their proper columns", {
  episodes <- read_episodes(raw_dir)
  row <- episodes[episodes$series == "Original" & episodes$title == "Mushrooms", ]
  testthat::expect_equal(nrow(row), 1L)
  testthat::expect_equal(c(row$victim_male, row$victim_black), c(1L, 1L))
  testthat::expect_equal(c(row$criminal_male, row$criminal_black), c(1L, 1L))
})

testthat::test_that("denominators use the same role as their numerators", {
  episodes <- read_episodes(raw_dir)
  shares <- estimate_shares(episodes)
  svu <- shares$aggregate[
    shares$aggregate$series == "SVU" & shares$aggregate$crime_group == "all" &
      shares$aggregate$role == "criminal" & shares$aggregate$group == "black",
  ]
  testthat::expect_equal(svu$count, 43)
  testthat::expect_equal(svu$known_total, 436)
  testthat::expect_equal(svu$share_pct, 100 * 43 / 436)

  for (subset in list(shares$aggregate, shares$yearly)) {
    period <- ifelse(is.na(subset$year), "all", as.character(subset$year))
    keys <- interaction(
      subset$series, period, subset$crime_group, subset$role,
      subset$dimension, drop = TRUE
    )
    groups <- split(subset, keys)
    testthat::expect_true(all(vapply(groups, function(group) {
      identical(sum(group$count), group$known_total[1])
    }, logical(1))))
  }
})
