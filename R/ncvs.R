read_ncvs_records <- function(path) {
  raw <- utils::read.csv(path, colClasses = "character", check.names = FALSE)
  fields <- c("year", "newoff", "sex", "race", "race_ethnicity", "offendersex", "newwgt")
  stopifnot(all(fields %in% names(raw)))
  records <- data.frame(
    year = as.integer(raw$year),
    offense = as.integer(raw$newoff),
    victim_sex = as.integer(raw$sex),
    victim_race = as.integer(raw$race),
    victim_race_ethnicity = as.integer(raw$race_ethnicity),
    offender_sex = as.integer(raw$offendersex),
    weight = as.numeric(raw$newwgt)
  )
  stopifnot(
    nrow(records) == 49717L,
    identical(sort(unique(records$year)), 1993:2014),
    all(records$offense %in% 1:5),
    all(records$victim_sex %in% 1:2),
    all(records$victim_race %in% 1:5),
    all(records$victim_race_ethnicity %in% 1:6),
    all(records$offender_sex %in% c(1:4, 98L)),
    all(is.finite(records$weight) & records$weight > 0)
  )
  records
}

ncvs_offense_codes <- list(
  violent = 1:4,
  serious_violent = 1:3,
  rape_sexual_assault = 1L,
  robbery = 2L,
  aggravated_assault = 3L,
  simple_assault = 4L,
  personal_larceny = 5L
)

ncvs_group_codes <- list(
  victim_white = list(column = "victim_race", codes = 1L),
  victim_black = list(column = "victim_race", codes = 2L),
  victim_male = list(column = "victim_sex", codes = 1L),
  victim_female = list(column = "victim_sex", codes = 2L),
  victim_nh_white = list(column = "victim_race_ethnicity", codes = 1L),
  victim_nh_black = list(column = "victim_race_ethnicity", codes = 2L),
  victim_nh_other = list(column = "victim_race_ethnicity", codes = 3:5),
  victim_hispanic = list(column = "victim_race_ethnicity", codes = 6L),
  offender_female_only = list(column = "offender_sex", codes = 2L)
)

ncvs_share <- function(records, years, offense, group) {
  stopifnot(offense %in% names(ncvs_offense_codes), group %in% names(ncvs_group_codes))
  selected <- records$year %in% years & records$offense %in% ncvs_offense_codes[[offense]]
  if (group == "offender_female_only") {
    selected <- selected & records$offender_sex %in% 1:3
  }
  part <- records[selected, ]
  definition <- ncvs_group_codes[[group]]
  is_group <- part[[definition$column]] %in% definition$codes
  numerator <- sum(part$weight[is_group])
  denominator <- sum(part$weight)
  data.frame(
    numerator = numerator,
    denominator = denominator,
    share_pct = if (denominator > 0) 100 * numerator / denominator else NA_real_,
    case_n = nrow(part)
  )
}

ncvs_annual_shares <- function(records) {
  definitions <- list(
    serious_violent_victimization_white = c("serious_violent", "victim_white"),
    serious_violent_victimization_black = c("serious_violent", "victim_black"),
    serious_violent_victimization_male = c("serious_violent", "victim_male"),
    rape_sexual_assault_white = c("rape_sexual_assault", "victim_white"),
    rape_sexual_assault_black = c("rape_sexual_assault", "victim_black"),
    rape_sexual_assault_male = c("rape_sexual_assault", "victim_male"),
    aggravated_assault_white = c("aggravated_assault", "victim_white"),
    aggravated_assault_black = c("aggravated_assault", "victim_black"),
    aggravated_assault_male = c("aggravated_assault", "victim_male")
  )
  ncvs <- data.frame(year = sort(unique(records$year)))
  for (name in names(definitions)) {
    item <- definitions[[name]]
    ncvs[[name]] <- vapply(ncvs$year, function(year) {
      ncvs_share(records, year, item[1], item[2])$share_pct
    }, numeric(1))
  }
  ncvs$serious_violent_offender_female_only <- vapply(ncvs$year, function(year) {
    ncvs_share(records, year, "serious_violent", "offender_female_only")$share_pct
  }, numeric(1))

  groups <- c(
    nh_white = "victim_nh_white", nh_black = "victim_nh_black",
    nh_other = "victim_nh_other", hispanic = "victim_hispanic"
  )
  offenses <- c(
    violent_victimization = "violent",
    serious_violent_victimization = "serious_violent",
    rape = "rape_sexual_assault", robbery = "robbery",
    aggravated_assault = "aggravated_assault", simple_assault = "simple_assault",
    larceny = "personal_larceny"
  )
  ncvs_hispanic <- data.frame(year = ncvs$year)
  for (offense_name in names(offenses)) {
    for (group_name in names(groups)) {
      name <- paste(offense_name, group_name, sep = "_")
      ncvs_hispanic[[name]] <- vapply(ncvs$year, function(year) {
        ncvs_share(records, year, offenses[[offense_name]], groups[[group_name]])$share_pct
      }, numeric(1))
    }
  }
  list(ncvs = ncvs, ncvs_hispanic = ncvs_hispanic)
}
