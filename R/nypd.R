read_nypd_race_counts <- function(directory) {
  sheets <- c(homicide = "page 1", rape = "page 2", robbery = "page 4", assault = "page 5")
  titles <- c(homicide = "Murder", rape = "Rape", robbery = "Robbery", assault = "Assault")
  rows <- lapply(2008:2015, function(year) {
    path <- file.path(directory, paste0("year=", year), "enforcement.xls")
    do.call(rbind, lapply(names(sheets), function(offense) {
      sheet <- as.data.frame(readxl::read_excel(
        path,
        sheet = if (year == 2010L && offense == "assault") "page5" else sheets[[offense]],
        col_names = FALSE,
        col_types = "text", .name_repair = "minimal"
      ))
      labels <- trimws(sheet[[1]])
      stopifnot(
        grepl(titles[[offense]], labels[1]),
        sum(labels == "BLACK", na.rm = TRUE) == 1L,
        sum(labels == "HISPANIC", na.rm = TRUE) == 1L,
        sum(grepl("^Known Race Ethnicity$|^Known Race/Ethnicity$", labels)) == 1L
      )
      known_row <- which(grepl("^Known Race Ethnicity$|^Known Race/Ethnicity$", labels))
      total_row <- which(labels %in% c("Total Victims/Suspects/Arrests", "Total Complaints/Arrests"))
      stopifnot(length(total_row) == 1L)
      do.call(rbind, lapply(c("BLACK", "HISPANIC", "WHITE"), function(category) {
        do.call(rbind, lapply(c(victim = 2L, suspect = 3L), function(column) {
          reported_pct <- 100 * as.numeric(sheet[which(labels == category), column][[1]])
          known_total <- as.integer(sheet[known_row, column][[1]])
          all_total <- as.integer(sheet[total_row, column][[1]])
          stopifnot(
            is.finite(reported_pct), reported_pct >= 0, reported_pct <= 100,
            known_total > 0L, all_total >= known_total
          )
          bounds <- infer_rounded_count(reported_pct, known_total, 0.1)
          data.frame(
            year = year, offense = offense,
            role = if (column == 2L) "victim" else "suspect",
            group = tolower(category), count_min = bounds[1], count_max = bounds[2],
            known_total = known_total, all_total = all_total, reported_pct = reported_pct
          )
        }))
      }))
    }))
  })
  do.call(rbind, rows)
}

pool_nypd_share <- function(counts, years, offense, role, group) {
  selected <- counts[
    counts$year %in% years & counts$offense == offense &
      counts$role == role & counts$group == group,
  ]
  stopifnot(nrow(selected) > 0L)
  50 * sum(selected$count_min + selected$count_max) / sum(selected$known_total)
}

read_nypd_rape_arrests <- function(path) {
  counts <- jsonlite::fromJSON(path)
  counts <- counts[c("year", "perp_sex", "n")]
  counts$year <- as.integer(counts$year)
  counts$n <- as.integer(counts$n)
  counts <- counts[order(counts$year, counts$perp_sex), ]
  rownames(counts) <- NULL
  stopifnot(
    identical(names(counts), c("year", "perp_sex", "n")),
    identical(sort(unique(counts$year)), 2008:2015),
    identical(sort(unique(counts$perp_sex)), c("F", "M")),
    nrow(counts) == 16L,
    !anyDuplicated(counts[c("year", "perp_sex")]),
    all(counts$n > 0L)
  )
  counts
}

pool_nypd_rape_arrests <- function(counts, years) {
  selected <- counts[counts$year %in% years, ]
  stopifnot(nrow(selected) == 2L * length(years))
  100 * sum(selected$n[selected$perp_sex == "F"]) / sum(selected$n)
}

nypd_rape_arrest_annual_shares <- function(counts) {
  years <- sort(unique(counts$year))
  data.frame(
    year = years,
    rape_female_arrests = vapply(years, function(year) {
      pool_nypd_rape_arrests(counts, year)
    }, numeric(1))
  )
}

infer_rounded_count <- function(share_pct, total, precision_pct) {
  lower <- max(0L, ceiling((share_pct - precision_pct / 2) * total / 100 - 1e-8))
  upper <- min(total, ceiling((share_pct + precision_pct / 2) * total / 100 - 1e-8) - 1L)
  stopifnot(is.finite(lower), is.finite(upper), lower <= upper)
  c(lower, upper)
}

nypd_race_annual_shares <- function(counts) {
  result <- data.frame(year = sort(unique(counts$year)))
  offenses <- c(homicide = "homicides", rape = "rapes", assault = "assaults", robbery = "robberies")
  for (offense in names(offenses)) {
    for (group in c("white", "black", "hispanic")) {
      for (role in c("victim", "suspect")) {
        part <- counts[counts$offense == offense & counts$group == group & counts$role == role, ]
        key <- paste(offenses[[offense]], group, role, sep = "_")
        result[[key]] <- part$reported_pct[match(result$year, part$year)]
      }
    }
  }
  result
}

extract_nypd_homicide_sex <- function(directory) {
  rows <- lapply(2010:2012, function(year) {
    path <- file.path(directory, paste0("year=", year), "murder_report.pdf")
    pages <- pdftools::pdf_text(path)
    stopifnot(length(pages) == 11L)
    do.call(rbind, lapply(c(5L, 9L), function(page) {
      text <- gsub("[[:space:]]+", " ", pages[page])
      share_matches <- regmatches(text, gregexpr("[0-9]+% were female", text))[[1]]
      total_matches <- regmatches(text, gregexpr(
        "[0-9]+ (persons were murdered|Homicide Victims|arrested murder suspects|known suspects)", text
      ))[[1]]
      stopifnot(length(share_matches) == 1L, length(total_matches) == 1L)
      reported_pct <- as.numeric(sub("%.*", "", share_matches))
      total <- as.integer(sub(" .*", "", total_matches))
      role <- if (page == 5L) "victim" else if (grepl("known suspects", text)) "suspect" else "arrestee"
      bounds <- infer_rounded_count(reported_pct, total, 1)
      data.frame(
        year = year, role = role, group = "female", reported_pct = reported_pct,
        total = total, count_min = bounds[1], count_max = bounds[2], precision_pct = 1,
        source_file = file.path(paste0("year=", year), "murder_report.pdf"), source_page = page
      )
    }))
  })
  do.call(rbind, rows)
}

pool_nypd_homicide_sex <- function(counts, years, role) {
  part <- counts[counts$year %in% years & counts$role == role, ]
  stopifnot(nrow(part) > 0L, !anyDuplicated(part$year))
  lower <- 100 * sum(part$count_min) / sum(part$total)
  upper <- 100 * sum(part$count_max) / sum(part$total)
  c(share_pct = (lower + upper) / 2, rounding_lower_pct = lower, rounding_upper_pct = upper)
}

nypd_homicide_annual_shares <- function(counts) {
  result <- data.frame(year = sort(unique(counts$year)))
  for (role in c("victim", "suspect", "arrestee")) {
    part <- counts[counts$role == role, ]
    result[[paste0("homicide_female_", role)]] <- part$reported_pct[match(result$year, part$year)]
  }
  result
}
