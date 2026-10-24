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

read_benchmarks <- function(raw_dir) {
  ncvs_records <- read_ncvs_records(file.path(raw_dir, "ncvs", "personal_victimizations.csv"))
  ncvs_annual <- ncvs_annual_shares(ncvs_records)
  ucr_counts <- read_ucr_arrest_counts(file.path(raw_dir, "ucr", "arrests.xlsx"))
  murder_victim_counts <- read_ucr_murder_victim_counts(file.path(raw_dir, "ucr", "homicide_victims.xlsx"))
  nypd_counts <- read_nypd_race_counts(file.path(raw_dir, "nypd", "enforcement"))
  nypd_homicide_counts <- extract_nypd_homicide_sex(file.path(raw_dir, "nypd", "homicide"))
  nypd_rape_arrests <- read_nypd_rape_arrests(file.path(
    raw_dir, "nypd", "arrests", "rape_arrests.json"
  ))
  census <- read_census_shares(file.path(raw_dir, "census", "population.xlsx"))

  list(
    census = census,
    ncvs = ncvs_annual$ncvs,
    ncvs_race_ethnicity = ncvs_annual$ncvs_race_ethnicity,
    ncvs_records = ncvs_records,
    ucr_counts = ucr_counts,
    murder_victim_counts = murder_victim_counts,
    nypd_counts = nypd_counts,
    nypd_rape_arrests = nypd_rape_arrests,
    nypd_homicide_counts = nypd_homicide_counts,
    nypd_homicide = nypd_homicide_annual_shares(nypd_homicide_counts),
    nypd_arrests = nypd_rape_arrest_annual_shares(nypd_rape_arrests),
    ucr = ucr_annual_shares(ucr_counts),
    ucr_hispanic = ucr_annual_shares(ucr_counts),
    murder_victims = murder_victim_annual_shares(murder_victim_counts),
    nypd_enforcement = nypd_race_annual_shares(nypd_counts)
  )
}

benchmark_catalog <- function() {
  reference <- function(source, column, role, group, label) {
    data.frame(source = source, column = column, role = role, group = group, label = label)
  }
  do.call(rbind, list(
    reference(
      "ncvs", "serious_violent_victimization_male",
      "victim", "female", "NCVS serious violence"
    ),
    reference(
      "ncvs", "rape_sexual_assault_male",
      "victim", "female", "NCVS rape/sexual assault"
    ),
    reference(
      "ncvs", "aggravated_assault_male",
      "victim", "female", "NCVS aggravated assault"
    ),
    reference(
      "ncvs_race_ethnicity", "serious_violent_victimization_nh_black",
      "victim", "black", "NCVS serious violence"
    ),
    reference(
      "ncvs_race_ethnicity", "rape_nh_black",
      "victim", "black", "NCVS rape/sexual assault"
    ),
    reference(
      "ncvs_race_ethnicity", "aggravated_assault_nh_black",
      "victim", "black", "NCVS aggravated assault"
    ),
    reference(
      "murder_victims", "murder_victim_men",
      "victim", "female", "UCR murder victims"
    ),
    reference(
      "murder_victims", "murder_victim_black",
      "victim", "black", "UCR murder victims"
    ),
    reference(
      "ucr", "all_crime_perc_men",
      "criminal", "female", "UCR all arrests"
    ),
    reference(
      "ucr", "violent_crime_perc_men",
      "criminal", "female", "UCR violent arrests"
    ),
    reference(
      "ucr", "homicides_perc_men",
      "criminal", "female", "UCR homicide arrests"
    ),
    reference(
      "ucr", "rape_perc_men",
      "criminal", "female", "UCR rape arrests"
    ),
    reference(
      "ucr", "assault_perc_men",
      "criminal", "female", "UCR assault arrests"
    ),
    reference(
      "ucr", "all_crime_perc_black",
      "criminal", "black", "UCR all arrests"
    ),
    reference(
      "ucr", "violent_crime_perc_black",
      "criminal", "black", "UCR violent arrests"
    ),
    reference(
      "ucr", "homicides_perc_black",
      "criminal", "black", "UCR homicide arrests"
    ),
    reference(
      "ucr", "rape_perc_black",
      "criminal", "black", "UCR rape arrests"
    ),
    reference(
      "ucr", "assault_perc_black",
      "criminal", "black", "UCR assault arrests"
    ),
    reference(
      "nypd_enforcement", "homicides_black_victim",
      "victim", "black", "NYPD homicide victims"
    ),
    reference(
      "nypd_enforcement", "rapes_black_victim",
      "victim", "black", "NYPD rape victims"
    ),
    reference(
      "nypd_enforcement", "homicides_black_suspect",
      "criminal", "black", "NYPD homicide suspects"
    ),
    reference(
      "nypd_enforcement", "rapes_black_suspect",
      "criminal", "black", "NYPD rape suspects"
    ),
    reference(
      "census", "men_us",
      "population", "female", "US Census"
    ),
    reference(
      "census", "men_ny",
      "population", "female", "NY Census"
    ),
    reference(
      "census", "black_us",
      "population", "black", "US Census"
    ),
    reference(
      "census", "black_ny",
      "population", "black", "NY Census"
    ),
    reference(
      "ncvs_race_ethnicity", "rape_hispanic",
      "victim", "hispanic", "NCVS rape/sexual assault"
    ),
    reference(
      "ncvs_race_ethnicity", "serious_violent_victimization_hispanic",
      "victim", "hispanic", "NCVS serious violence"
    ),
    reference(
      "ncvs_race_ethnicity", "aggravated_assault_hispanic",
      "victim", "hispanic", "NCVS aggravated assault"
    ),
    reference(
      "ucr_hispanic", "all_crime_perc_hispanic",
      "criminal", "hispanic", "UCR all arrests"
    ),
    reference(
      "ucr_hispanic", "homicides_perc_hispanic",
      "criminal", "hispanic", "UCR homicide arrests"
    ),
    reference(
      "ucr_hispanic", "rape_perc_hispanic",
      "criminal", "hispanic", "UCR rape arrests"
    ),
    reference(
      "ncvs", "serious_violent_offender_female_only",
      "criminal", "female", "NCVS female-only offender incidents"
    ),
    reference(
      "nypd_enforcement", "homicides_hispanic_victim",
      "victim", "hispanic", "NYPD homicide victims"
    ),
    reference(
      "nypd_enforcement", "rapes_hispanic_victim",
      "victim", "hispanic", "NYPD rape victims"
    ),
    reference(
      "nypd_enforcement", "homicides_hispanic_suspect",
      "criminal", "hispanic", "NYPD homicide suspects"
    ),
    reference(
      "nypd_enforcement", "rapes_hispanic_suspect",
      "criminal", "hispanic", "NYPD rape suspects"
    ),
    reference(
      "nypd_arrests", "rape_female_arrests",
      "criminal", "female", "NYPD rape arrests"
    ),
    reference(
      "nypd_homicide", "homicide_female_victim",
      "victim", "female", "NYPD homicide victims (2010-2012)"
    ),
    reference(
      "nypd_homicide", "homicide_female_suspect",
      "criminal", "female", "NYPD homicide suspects (2011-2012)"
    )
  ))
}

pooled_benchmarks <- function(benchmarks, episodes) {
  catalog <- benchmark_catalog()
  catalog <- catalog[catalog$source != "census", ]
  show_years <- sort(unique(episodes$year))
  rows <- lapply(seq_len(nrow(catalog)), function(i) {
    item <- catalog[i, ]
    source <- item$source
    available <- switch(source,
      ncvs = benchmarks$ncvs_records$year,
      ncvs_race_ethnicity = benchmarks$ncvs_records$year,
      ucr = benchmarks$ucr_counts$year,
      ucr_hispanic = benchmarks$ucr_counts$year[!is.na(benchmarks$ucr_counts$hispanic)],
      murder_victims = benchmarks$murder_victim_counts$year,
      nypd_enforcement = benchmarks$nypd_counts$year,
      nypd_arrests = benchmarks$nypd_rape_arrests$year,
      nypd_homicide = benchmarks$nypd_homicide_counts$year[
        benchmarks$nypd_homicide_counts$role == if (item$role == "victim") "victim" else "suspect"
      ]
    )
    years <- intersect(show_years, unique(available))
    if (length(years) == 0L) {
      return(NULL)
    }
    rounding_lower <- rounding_upper <- NA_real_
    if (source %in% c("ncvs", "ncvs_race_ethnicity")) {
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
    } else if (source == "nypd_enforcement") {
      offense <- if (grepl("homicides", item$column)) "homicide" else "rape"
      nypd_role <- if (item$role == "victim") "victim" else "suspect"
      value <- pool_nypd_share(benchmarks$nypd_counts, years, offense, nypd_role, item$group)
    } else if (source == "nypd_arrests") {
      value <- pool_nypd_rape_arrests(benchmarks$nypd_rape_arrests, years)
    } else if (source == "nypd_homicide") {
      result <- pool_nypd_homicide_sex(
        benchmarks$nypd_homicide_counts, years, if (item$role == "victim") "victim" else "suspect"
      )
      value <- unname(result["share_pct"])
      rounding_lower <- unname(result["rounding_lower_pct"])
      rounding_upper <- unname(result["rounding_upper_pct"])
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
      share_pct = value, rounding_lower_pct = rounding_lower, rounding_upper_pct = rounding_upper
    )
  })
  do.call(rbind, rows)
}
