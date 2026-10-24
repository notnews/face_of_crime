reference_inventory <- function(pooled, sources, episodes) {
  rows <- pooled
  ethnicity_years <- intersect(unique(episodes$year), sources$ucr_counts$year[!is.na(sources$ucr_counts$hispanic)])
  for (offense in c("violent", "assault")) {
    counts <- sources$ucr_counts[sources$ucr_counts$offense == offense, ]
    rows <- rbind(rows, data.frame(
      source = "ucr_hispanic", column = paste0(offense, "_perc_hispanic"), role = "criminal", group = "hispanic",
      label = paste("UCR", offense, "arrests"), first_year = min(ethnicity_years), last_year = max(ethnicity_years),
      n_years = length(ethnicity_years), share_pct = pool_count_share(counts, ethnicity_years, "hispanic"),
      rounding_lower_pct = NA_real_, rounding_upper_pct = NA_real_
    ))
  }
  years <- intersect(unique(episodes$year), sources$nypd_counts$year)
  for (offense in c("robbery", "assault")) {
    for (role in c("victim", "suspect")) {
      for (group in c("black", "hispanic")) {
        part <- sources$nypd_counts[
          sources$nypd_counts$year %in% years & sources$nypd_counts$offense == offense &
            sources$nypd_counts$role == role & sources$nypd_counts$group == group,
        ]
        rows <- rbind(rows, data.frame(
          source = "nypd_enforcement", column = paste(offense, group, role, sep = "_"),
          role = if (role == "suspect") "criminal" else "victim", group = group,
          label = paste("NYPD", if (offense == "assault") "felonious assault" else offense, paste0(role, "s")),
          first_year = min(years), last_year = max(years), n_years = length(years),
          share_pct = pool_nypd_share(sources$nypd_counts, years, offense, role, group),
          rounding_lower_pct = 100 * sum(part$count_min) / sum(part$known_total),
          rounding_upper_pct = 100 * sum(part$count_max) / sum(part$known_total)
        ))
      }
    }
  }
  for (i in which(rows$source == "nypd_enforcement")) {
    offense <- if (grepl("homicide", rows$column[i])) "homicide" else if (grepl("rape", rows$column[i])) "rape"
    if (is.null(offense)) next
    part <- sources$nypd_counts[
      sources$nypd_counts$year %in% years & sources$nypd_counts$offense == offense &
        sources$nypd_counts$role == if (rows$role[i] == "victim") "victim" else "suspect",
    ]
    part <- part[part$group == rows$group[i], ]
    rows$rounding_lower_pct[i] <- 100 * sum(part$count_min) / sum(part$known_total)
    rows$rounding_upper_pct[i] <- 100 * sum(part$count_max) / sum(part$known_total)
  }
  arrested <- pool_nypd_homicide_sex(sources$nypd_homicide_counts, 2010L, "arrestee")
  rbind(rows, data.frame(
    source = "nypd_homicide", column = "homicide_female_arrestee", role = "criminal", group = "female",
    label = "NYPD homicide arrestees", first_year = 2010L, last_year = 2010L, n_years = 1L,
    share_pct = unname(arrested["share_pct"]), rounding_lower_pct = unname(arrested["rounding_lower_pct"]),
    rounding_upper_pct = unname(arrested["rounding_upper_pct"])
  ))
}

write_reference_tables <- function(pooled, sources, episodes, directory) {
  inventory <- reference_inventory(pooled, sources, episodes)
  utils::write.csv(inventory, file.path(directory, "reference_inventory.csv"), row.names = FALSE, na = "")
  inventory$label <- sub(" \\(20[0-9-]+\\)$", "", inventory$label)
  for (role in c("criminal", "victim")) {
    selected <- inventory[inventory$role == role, ]
    labels <- sort(unique(selected$label))
    body <- vapply(labels, function(label) {
      part <- selected[selected$label == label, ]
      cells <- vapply(c("black", "hispanic", "female"), function(group) {
        row <- part[part$group == group, ]
        if (nrow(row) == 0L) {
          return("--")
        }
        stopifnot(nrow(row) == 1L)
        years <- if (row$first_year == row$last_year) {
          as.character(row$first_year)
        } else {
          paste0(row$first_year, "--", substr(row$last_year, 3, 4))
        }
        paste0(sprintf("%.1f", row$share_pct), " {\\scriptsize (", years, ")}")
      }, character(1))
      paste0(paste(c(label, cells), collapse = " & "), " \\\\")
    }, character(1))
    lines <- c(
      "\\begin{center}",
      paste0("\\captionof{table}{Pooled ", if (role == "criminal") "Arrest and Suspect" else "Victim", " References}"),
      paste0("\\label{tab:", role, "_references}"),
      "\\small\\setlength{\\tabcolsep}{4pt}\\renewcommand{\\arraystretch}{1.25}",
      "\\begin{tabular}{@{}>{\\raggedright\\arraybackslash}p{.38\\linewidth}rrr@{}}",
      "\\toprule Reference & Black & Hispanic & Female \\\\", "\\midrule", body,
      "\\bottomrule\\end{tabular}", "\\par\\smallskip",
      "\\parbox{\\linewidth}{\\footnotesize\\raggedright Entries are percentages; years are in parentheses.",
      "-- indicates that this reference is not constructed from the preserved sources.",
      "NYPD homicide sex shares are reconstructed from whole-percent reports; other NYPD race shares",
      "are reconstructed from one-decimal reports. See the source definitions and rounding ranges below.",
      "Black excludes Hispanic people in NCVS and NYPD, but includes them in UCR.",
      "NCVS female-only offender incidents use a different unit from arrests and suspects.}",
      "\\end{center}"
    )
    writeLines(lines, file.path(directory, paste0(role, "_references.tex")))
  }
  homicide <- inventory[inventory$source == "nypd_homicide", ]
  lines <- vapply(seq_len(nrow(homicide)), function(i) {
    row <- homicide[i, ]
    paste0(
      row$label, ": ", row$first_year, if (row$last_year != row$first_year) paste0("--", row$last_year),
      ", ", sprintf("%.2f--%.2f", row$rounding_lower_pct, row$rounding_upper_pct), "\\%"
    )
  }, character(1))
  writeLines(paste0(paste(lines, collapse = "; "), "."), file.path(directory, "reference_rounding.tex"))
}
