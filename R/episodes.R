episode_columns <- c(
  "season", "episode", "year", "title", "crime", "n_victims",
  "victim_gender", "victim_race", "n_criminals", "criminal_gender",
  "criminal_race", "notes"
)

read_episode_file <- function(path, series, svu_part = NULL) {
  rows <- utils::read.csv(path, na.strings = c("", "NA"), stringsAsFactors = FALSE)

  if (series %in% c("Criminal Intent", "Original")) {
    names(rows) <- episode_columns
  } else {
    if (identical(svu_part, "season_1")) {
      rows$crime <- paste(rows$crime1, rows$crime2, sep = "; ")
      rows$notes <- NA_character_
    }
    names(rows)[names(rows) == "v_sex"] <- "victim_gender"
    names(rows)[names(rows) == "v_race"] <- "victim_race"
    names(rows)[names(rows) == "c_sex"] <- "criminal_gender"
    names(rows)[names(rows) == "c_race"] <- "criminal_race"
    rows <- rows[episode_columns]
  }

  rows$series <- series
  rows$source_file <- basename(path)
  rows
}

parse_categories <- function(value, categories) {
  counts <- stats::setNames(integer(length(categories)), categories)
  if (is.na(value) || !nzchar(trimws(value))) {
    return(counts)
  }

  tokens <- strsplit(tolower(value), ",", fixed = TRUE)[[1]]
  for (token in tokens) {
    token <- trimws(token)
    if (grepl("*", token, fixed = TRUE)) {
      next
    }
    match <- regexec("^([0-9]+)?[[:space:]]*([[:alpha:]]+)", token)
    parts <- regmatches(token, match)[[1]]
    if (length(parts) < 3L) {
      next
    }
    category <- sub("s$", "", parts[3])
    if (category %in% categories) {
      quantity <- if (nzchar(parts[2])) as.integer(parts[2]) else 1L
      counts[category] <- counts[category] + quantity
    }
  }
  counts
}

add_category_counts <- function(rows, role, dimension, categories) {
  column <- paste(role, dimension, sep = "_")
  parsed <- t(vapply(rows[[column]], parse_categories, integer(length(categories)), categories))
  for (category in categories) {
    rows[[paste(role, category, sep = "_")]] <- parsed[, category]
  }
  rows
}

read_episodes <- function(raw_dir) {
  inputs <- list(
    list("ci/law_and_order_ci.csv", "Criminal Intent", NULL),
    list("lo/law_and_order_lo.csv", "Original", NULL),
    list("svu/law_and_order_svu_1.csv", "SVU", "season_1"),
    list("svu/law_and_order_svu_2.csv", "SVU", NULL),
    list("svu/law_and_order_svu_3_5.csv", "SVU", NULL),
    list("svu/law_and_order_svu_6_17.csv", "SVU", NULL)
  )
  parts <- lapply(inputs, function(input) {
    read_episode_file(file.path(raw_dir, input[[1]]), input[[2]], input[[3]])
  })
  rows <- do.call(rbind, parts)
  rownames(rows) <- NULL

  mushrooms <- rows$series == "Original" & rows$season == 1 & rows$episode == 17 & rows$title == "Mushrooms"
  stopifnot(sum(mushrooms) == 1L)
  stopifnot(
    rows$victim_gender[mushrooms] == "Black", rows$victim_race[mushrooms] == "Male",
    rows$criminal_gender[mushrooms] == "Black", rows$criminal_race[mushrooms] == "Male"
  )
  for (role in c("victim", "criminal")) {
    gender <- paste0(role, "_gender")
    race <- paste0(role, "_race")
    rows[[gender]][mushrooms] <- "Male"
    rows[[race]][mushrooms] <- "Black"
  }

  for (role in c("victim", "criminal")) {
    rows <- add_category_counts(rows, role, "gender", c("male", "female"))
    rows <- add_category_counts(rows, role, "race", c("white", "black", "hispanic", "asian"))
  }
  rows$season <- as.integer(rows$season)
  rows$episode <- as.character(rows$episode)
  rows$year <- as.integer(rows$year)
  rows$is_murder <- grepl("murder", rows$crime, ignore.case = TRUE)
  rows$is_rape <- grepl("rape", rows$crime, ignore.case = TRUE) &
    !grepl("false rape", rows$crime, ignore.case = TRUE)
  rows$is_assault <- grepl("assault", rows$crime, ignore.case = TRUE)
  rows
}

episode_diagnostics <- function(rows) {
  diagnostics <- list()
  for (role in c("victim", "criminal")) {
    count_col <- paste0("n_", role, "s")
    declared <- suppressWarnings(as.numeric(rows[[count_col]]))
    for (dimension in c("gender", "race")) {
      categories <- if (dimension == "gender") {
        c("male", "female")
      } else {
        c("white", "black", "hispanic", "asian")
      }
      classified <- rowSums(rows[paste(role, categories, sep = "_")])
      flag <- !is.na(declared) & classified > declared
      diagnostics[[paste(role, dimension, sep = "_")]] <- data.frame(
        series = rows$series[flag], season = rows$season[flag],
        episode = rows$episode[flag], title = rows$title[flag],
        declared = declared[flag], classified = classified[flag],
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, diagnostics)
}
