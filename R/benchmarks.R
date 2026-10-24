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
  ncvs_records <- read_ncvs_records(file.path(reference_dir, "ncvs", "personal_victimizations_1993_2014.csv"))
  ncvs_annual <- ncvs_annual_shares(ncvs_records)
  ucr_counts <- read_ucr_arrest_counts(file.path(reference_dir, "ucr", "race_gender_criminals.xlsx"))
  murder_victim_counts <- read_ucr_murder_victim_counts(file.path(reference_dir, "ucr", "Murder victim data.xlsx"))
  census <- read_percent_table(file.path(reference_dir, "census", "census.csv"))
  names(census) <- c(
    "year", "white_us", "black_us", "men_us", "white_ny",
    "black_ny", "hispanic_ny", "non_hispanic_white_ny", "men_ny"
  )

  list(
    census = census,
    ncvs = ncvs_annual$ncvs,
    ncvs_hispanic = ncvs_annual$ncvs_hispanic,
    ncvs_records = ncvs_records,
    ucr_counts = ucr_counts,
    murder_victim_counts = murder_victim_counts,
    ucr = ucr_annual_shares(ucr_counts),
    ucr_hispanic = read_percent_table(file.path(reference_dir, "ucr", "race_gender_criminals_hispanic.csv")),
    murder_victims = murder_victim_annual_shares(murder_victim_counts),
    nyc = read_percent_table(file.path(reference_dir, "ny_enforcement", "nyc_enforcement.csv"))
  )
}

benchmark_catalog <- function() {
  catalog <- data.frame(
    source = c(
      rep("ncvs", 3), rep("ncvs_hispanic", 3), rep("murder_victims", 2), rep("ucr", 10),
      rep("nyc", 4), rep("census", 4), rep("ncvs_hispanic", 3),
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
      "rape_hispanic", "serious_violent_victimization_hispanic", "aggravated_assault_hispanic",
      "all_crime_perc_hispanic", "homicides_perc_hispanic", "rape_perc_hispanic"
    ),
    role = c(
      rep("victim", 8), rep("criminal", 10),
      "victim", "victim", "criminal", "criminal",
      "population", "population", "population", "population",
      "victim", "victim", "victim", rep("criminal", 3)
    ),
    group = c(
      rep("female", 3), rep("black", 3), "female", "black",
      rep("female", 5), rep("black", 5), rep("black", 4),
      "female", "female", "black", "black",
      "hispanic", "hispanic", "hispanic", rep("hispanic", 3)
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
      "NCVS rape/sexual assault", "NCVS serious violence", "NCVS aggravated assault",
      "UCR all arrests", "UCR homicide arrests", "UCR rape arrests"
    ),
    stringsAsFactors = FALSE
  )
  rbind(catalog, data.frame(
    source = "ncvs", column = "serious_violent_offender_female_only",
    role = "criminal", group = "female", label = "NCVS female-only offender incidents"
  ))
}

pooled_benchmarks <- function(benchmarks, episodes) {
  catalog <- benchmark_catalog()
  catalog <- catalog[!catalog$source %in% c("census", "nyc"), ]
  show_years <- sort(unique(episodes$year))
  rows <- lapply(seq_len(nrow(catalog)), function(i) {
    item <- catalog[i, ]
    source <- item$source
    available <- switch(source,
      ncvs = benchmarks$ncvs_records$year,
      ncvs_hispanic = benchmarks$ncvs_records$year,
      ucr = benchmarks$ucr_counts$year,
      ucr_hispanic = benchmarks$ucr_counts$year[!is.na(benchmarks$ucr_counts$hispanic)],
      murder_victims = benchmarks$murder_victim_counts$year
    )
    years <- intersect(show_years, unique(available))
    if (length(years) == 0L) return(NULL)
    if (source %in% c("ncvs", "ncvs_hispanic")) {
      offense <- if (grepl("rape", item$column)) {
        "rape_sexual_assault"
      } else if (grepl("aggravated", item$column)) {
        "aggravated_assault"
      } else {
        "serious_violent"
      }
      group <- if (grepl("offender_female_only", item$column)) {
        "offender_female_only"
      } else if (item$group == "female") {
        "victim_female"
      } else {
        paste0("victim_", if (item$group == "black") "nh_black" else "hispanic")
      }
      value <- ncvs_share(benchmarks$ncvs_records, years, offense, group)$share_pct
    } else {
      counts <- if (source == "murder_victims") {
        benchmarks$murder_victim_counts
      } else {
        offense <- if (grepl("all_crime", item$column)) {
          "all"
        } else if (grepl("violent_crime", item$column)) {
          "violent"
        } else if (grepl("homicides", item$column)) {
          "homicide"
        } else if (grepl("rape", item$column)) {
          "rape"
        } else {
          "assault"
        }
        benchmarks$ucr_counts[benchmarks$ucr_counts$offense == offense, ]
      }
      value <- pool_count_share(counts, years, item$group)
    }
    data.frame(
      source = source, column = item$column,
      role = item$role, group = item$group, label = item$label,
      first_year = min(years), last_year = max(years), n_years = length(years),
      share_pct = value
    )
  })
  do.call(rbind, rows)
}
