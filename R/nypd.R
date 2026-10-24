read_nypd_race_counts <- function(directory) {
  sheets <- c(homicide = "page 1", rape = "page 2")
  rows <- lapply(2008:2015, function(year) {
    path <- file.path(directory, paste("Enforcement Report Year", year, "tables.xls"))
    do.call(rbind, lapply(names(sheets), function(offense) {
      sheet <- as.data.frame(readxl::read_excel(
        path, sheet = sheets[[offense]], col_names = FALSE,
        col_types = "text", .name_repair = "minimal"
      ))
      labels <- trimws(sheet[[1]])
      stopifnot(
        grepl(if (offense == "homicide") "Murder" else "Rape", labels[1]),
        sum(labels == "BLACK", na.rm = TRUE) == 1L,
        sum(grepl("^Known Race Ethnicity$|^Known Race/Ethnicity$", labels)) == 1L
      )
      black_row <- which(labels == "BLACK")
      known_row <- which(grepl("^Known Race Ethnicity$|^Known Race/Ethnicity$", labels))
      total_row <- which(labels %in% c("Total Victims/Suspects/Arrests", "Total Complaints/Arrests"))
      stopifnot(length(total_row) == 1L)
      do.call(rbind, lapply(c(victim = 2L, suspect = 3L), function(column) {
        reported_pct <- 100 * as.numeric(sheet[black_row, column][[1]])
        known_total <- as.integer(sheet[known_row, column][[1]])
        all_total <- as.integer(sheet[total_row, column][[1]])
        stopifnot(
          is.finite(reported_pct), reported_pct >= 0, reported_pct <= 100,
          known_total > 0L, all_total >= known_total
        )
        black_min <- max(0L, ceiling((reported_pct - 0.05) * known_total / 100 - 1e-8))
        black_max <- min(known_total, floor((reported_pct + 0.05) * known_total / 100 + 1e-8))
        stopifnot(black_min <= black_max, black_max - black_min <= 1L)
        data.frame(
          year = year, offense = offense,
          role = if (column == 2L) "victim" else "suspect",
          black_min = black_min, black_max = black_max,
          known_total = known_total, reported_pct = reported_pct
        )
      }))
    }))
  })
  do.call(rbind, rows)
}

pool_nypd_share <- function(counts, years, offense, role) {
  selected <- counts[
    counts$year %in% years & counts$offense == offense & counts$role == role,
  ]
  stopifnot(nrow(selected) > 0L)
  50 * sum(selected$black_min + selected$black_max) / sum(selected$known_total)
}
