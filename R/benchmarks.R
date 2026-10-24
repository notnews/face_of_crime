read_percent_table <- function(path) {
  rows <- utils::read.csv(path, na.strings = c("", "NA", "--"))
  names(rows) <- tolower(names(rows))
  for (name in setdiff(names(rows), "year")) {
    rows[[name]] <- as.numeric(gsub("%", "", rows[[name]], fixed = TRUE))
  }
  rows$year <- as.integer(rows$year)
  stopifnot(!anyDuplicated(rows$year))
  rows
}

read_benchmarks <- function(reference_dir) {
  census <- read_percent_table(file.path(reference_dir, "census", "census.csv"))
  names(census) <- c(
    "year", "white_us", "black_us", "men_us", "white_ny",
    "black_ny", "hispanic_ny", "non_hispanic_white_ny", "men_ny"
  )

  list(
    census = census,
    ncvs = read_percent_table(file.path(reference_dir, "ncvs", "ncvs.csv")),
    ncvs_hispanic = read_percent_table(file.path(reference_dir, "ncvs", "ncvs_hispanic.csv")),
    ucr = read_percent_table(file.path(reference_dir, "ucr", "race_gender_criminals.csv")),
    ucr_hispanic = read_percent_table(file.path(reference_dir, "ucr", "race_gender_criminals_hispanic.csv")),
    murder_victims = read_percent_table(file.path(reference_dir, "ucr", "murder_victim_race_gender.csv")),
    nyc = read_percent_table(file.path(reference_dir, "ny_enforcement", "nyc_enforcement.csv"))
  )
}

benchmark_catalog <- function() {
  data.frame(
    source = c(
      rep("ncvs", 3), rep("ncvs_hispanic", 3), rep("murder_victims", 2), rep("ucr", 10),
      rep("nyc", 4), rep("census", 4), rep("ncvs_hispanic", 2),
      rep("ucr_hispanic", 3)
    ),
    column = c(
      "serious_violent_victimization_male", "rape_sexual_assault_male",
      "aggravated_assault_male", "serious_violent_victimization_nh_black",
      "rape_nh_black", "aggravated_assault_nh_black",
      "murder_victim_men", "murder_victim_black",
      "all_crime_perc_men", "violent_crime_perc_men", "homicides_perc_men",
      "rape_perc_men", "assault_perc_men", "all_crime_perc_black",
      "violent_crime_perc_black", "homicides_perc_black", "rape_perc_black",
      "assault_perc_black", "homicides_black_victim", "rapes_black_victim",
      "homicides_black_suspect", "rapes_black_suspect",
      "men_us", "men_ny", "black_us", "black_ny",
      "rape_hispanic", "serious_violent_victimization_hispanic",
      "all_crime_perc_hispanic", "homicides_perc_hispanic", "rape_perc_hispanic"
    ),
    role = c(
      rep("victim", 8), rep("criminal", 10),
      "victim", "victim", "criminal", "criminal",
      "population", "population", "population", "population",
      "victim", "victim", rep("criminal", 3)
    ),
    group = c(
      rep("female", 3), rep("black", 3), "female", "black",
      rep("female", 5), rep("black", 5), rep("black", 4),
      "female", "female", "black", "black",
      "hispanic", "hispanic", rep("hispanic", 3)
    ),
    label = c(
      "NCVS serious violence", "NCVS rape/sexual assault", "NCVS aggravated assault",
      "NCVS serious violence", "NCVS rape/sexual assault", "NCVS aggravated assault",
      "UCR murder victims", "UCR murder victims",
      "UCR all arrests", "UCR violent arrests", "UCR homicide arrests",
      "UCR rape arrests", "UCR assault arrests", "UCR all arrests",
      "UCR violent arrests", "UCR homicide arrests", "UCR rape arrests",
      "UCR assault arrests", "NYPD homicide victims", "NYPD rape victims",
      "NYPD homicide suspects", "NYPD rape suspects",
      "US Census", "NY Census", "US Census", "NY Census",
      "NCVS rape/sexual assault", "NCVS serious violence",
      "UCR all arrests", "UCR homicide arrests", "UCR rape arrests"
    ),
    stringsAsFactors = FALSE
  )
}

summarise_benchmarks <- function(benchmarks) {
  catalog <- benchmark_catalog()
  rows <- lapply(seq_len(nrow(catalog)), function(i) {
    item <- catalog[i, ]
    source <- benchmarks[[item$source]]
    values <- source[[item$column]]
    if (item$group == "female") {
      values <- 100 - values
    }
    valid <- !is.na(values)
    data.frame(
      source = item$source, column = item$column, role = item$role,
      group = item$group, label = item$label,
      first_year = min(source$year[valid]), last_year = max(source$year[valid]),
      n_years = sum(valid), mean_pct = mean(values[valid]),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
