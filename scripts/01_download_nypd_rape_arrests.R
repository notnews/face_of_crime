endpoint <- "https://data.cityofnewyork.us/resource/8h9b-rp9u.json"
query <- c(
  `$select` = "date_extract_y(arrest_date) as year, perp_sex, count(*) as n",
  `$where` = paste(
    "arrest_date between '2008-01-01T00:00:00' and '2015-12-31T23:59:59'",
    "and ofns_desc='RAPE'"
  ),
  `$group` = "year,perp_sex",
  `$limit` = "100"
)
url <- paste0(
  endpoint, "?",
  paste(
    paste0(
      vapply(names(query), utils::URLencode, character(1), reserved = TRUE),
      "=",
      vapply(query, utils::URLencode, character(1), reserved = TRUE)
    ),
    collapse = "&"
  )
)
counts <- jsonlite::fromJSON(url)
stopifnot(
  identical(sort(unique(as.integer(counts$year))), 2008:2015),
  identical(sort(unique(counts$perp_sex)), c("F", "M")),
  nrow(counts) == 16L
)
counts$year <- as.integer(counts$year)
counts$n <- as.integer(counts$n)
counts <- counts[order(counts$year, counts$perp_sex), ]
path <- "data/reference/ny_arrests/rape_arrests_by_sex_2008_2015.csv"
dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(counts, path, row.names = FALSE)
