read_ucr_arrest_counts <- function(path) {
  years <- 1995:2015
  stopifnot(all(as.character(years) %in% readxl::excel_sheets(path)))
  offenses <- c(all = 3L, homicide = 4L, rape = 5L, assault = 7L, violent = 12L)
  rows <- lapply(years, function(year) {
    sheet <- as.data.frame(readxl::read_excel(
      path, sheet = as.character(year), col_names = FALSE, col_types = "text",
      .name_repair = "minimal", n_max = 12
    ))
    stopifnot(grepl("TOTAL", sheet[3, 1], fixed = TRUE))
    sex_start <- if (year < 2013) 14L else 22L
    do.call(rbind, lapply(names(offenses), function(offense) {
      row <- offenses[[offense]]
      expected <- switch(offense,
        all = "TOTAL", homicide = "Murder", rape = "rape",
        assault = "Aggravated assault", violent = "Violent crime"
      )
      stopifnot(grepl(expected, sheet[row, 1], ignore.case = TRUE))
      race_total <- as.numeric(sheet[row, 2])
      black <- as.numeric(sheet[row, 4])
      sex_total <- as.numeric(sheet[row, sex_start])
      female <- as.numeric(sheet[row, sex_start + 2L])
      ethnicity_total <- if (year >= 2013) as.numeric(sheet[row, 14]) else NA_real_
      hispanic <- if (year >= 2013) as.numeric(sheet[row, 15]) else NA_real_
      stopifnot(
        is.finite(race_total), is.finite(black), is.finite(sex_total),
        is.finite(female), black <= race_total, female <= sex_total,
        year < 2013 || (is.finite(ethnicity_total) && is.finite(hispanic))
      )
      data.frame(
        year = year, offense = offense,
        black = black, race_total = race_total,
        female = female, sex_total = sex_total,
        hispanic = hispanic, ethnicity_total = ethnicity_total
      )
    }))
  })
  do.call(rbind, rows)
}

read_ucr_murder_victim_counts <- function(path) {
  years <- 1995:2015
  stopifnot(all(as.character(years) %in% readxl::excel_sheets(path)))
  rows <- lapply(years, function(year) {
    sheet <- as.data.frame(readxl::read_excel(
      path, sheet = as.character(year), col_names = FALSE, col_types = "text",
      .name_repair = "minimal", n_max = 10
    ))
    stopifnot(
      grepl("White", sheet[6, 1], ignore.case = TRUE),
      grepl("Black", sheet[7, 1], ignore.case = TRUE),
      grepl("Total", sheet[10, 1], ignore.case = TRUE)
    )
    data.frame(
      year = year, black = as.numeric(sheet[7, 2]),
      race_total = as.numeric(sheet[10, 2]),
      female = as.numeric(sheet[10, 4]),
      sex_total = as.numeric(sheet[10, 2])
    )
  })
  do.call(rbind, rows)
}

pool_count_share <- function(counts, years, group) {
  part <- counts[counts$year %in% years, ]
  stopifnot(nrow(part) > 0L)
  part <- part[!is.na(part[[group]]), ]
  stopifnot(nrow(part) > 0L)
  denominator <- switch(group,
    black = "race_total", female = "sex_total", hispanic = "ethnicity_total"
  )
  100 * sum(part[[group]]) / sum(part[[denominator]])
}

ucr_annual_shares <- function(counts) {
  result <- data.frame(year = sort(unique(counts$year)))
  labels <- c(
    all = "all_crime", violent = "violent_crime", homicide = "homicides",
    rape = "rape", assault = "assault"
  )
  for (offense in names(labels)) {
    part <- counts[counts$offense == offense, ]
    prefix <- paste0(labels[[offense]], "_perc_")
    result[[paste0(prefix, "black")]] <- 100 * part$black / part$race_total
    result[[paste0(prefix, "men")]] <- 100 * (part$sex_total - part$female) / part$sex_total
  }
  result
}

murder_victim_annual_shares <- function(counts) {
  data.frame(
    year = counts$year,
    murder_victim_black = 100 * counts$black / counts$race_total,
    murder_victim_men = 100 * (counts$sex_total - counts$female) / counts$sex_total
  )
}
