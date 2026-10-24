format_percent <- function(value) {
  ifelse(is.na(value), "--", sprintf("%.1f", value))
}

annual_table <- function(yearly, benchmarks, catalog, role, group) {
  values <- yearly[yearly$role == role & yearly$group == group, ]
  years <- sort(unique(values$year))
  table <- data.frame(Year = years)
  for (series in c("Criminal Intent", "Original", "SVU")) {
    part <- values[values$series == series, c("year", "share_pct")]
    table[[series]] <- part$share_pct[match(years, part$year)]
  }

  selected <- catalog[
    (catalog$role == role | catalog$role == "population") & catalog$group == group,
  ]
  for (i in seq_len(nrow(selected))) {
    item <- selected[i, ]
    source <- benchmarks[[item$source]]
    key <- item$label
    values <- source[[item$column]]
    if (group == "female") values <- 100 - values
    table[[key]] <- values[match(years, source$year)]
  }
  table
}

write_latex_table <- function(table, path, caption, label) {
  headers <- names(table)
  header <- paste(headers, collapse = " & ")
  body <- apply(table, 1, function(row) {
    paste(c(row[1], format_percent(as.numeric(row[-1]))), collapse = " & ")
  })
  lines <- c(
    "\\begin{sidewaystable}[p]",
    "\\centering",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    "\\scriptsize",
    "\\resizebox{\\linewidth}{!}{%",
    paste0("\\begin{tabular}{l", paste(rep("r", ncol(table) - 1L), collapse = ""), "}"),
    "\\toprule", paste0(header, " \\\\"), "\\midrule",
    paste0(body, " \\\\"), "\\bottomrule", "\\end{tabular}%",
    "}",
    "\\par\\smallskip",
    paste0(
      "\\parbox{\\linewidth}{\\footnotesize Show columns pool classified characters across",
      " all coded episodes broadcast that year. NCVS columns are survey-estimated victimizations;",
      " UCR and NYPD columns are recorded arrests, suspects, or victims for the named offense.",
      " Census columns describe population. The sources use different offenses and populations;",
      " missing years are shown as --.}"
    ),
    "\\end{sidewaystable}"
  )
  writeLines(lines, path)
}

macro_line <- function(name, value) {
  paste0("\\newcommand{\\", name, "}{", value, "}")
}

write_macros <- function(aggregate, benchmarks, episodes, source_tables, path) {
  all <- aggregate[aggregate$crime_group == "all", ]
  total_victims <- sum(suppressWarnings(as.numeric(episodes$n_victims)), na.rm = TRUE)
  total_criminals <- sum(suppressWarnings(as.numeric(episodes$n_criminals)), na.rm = TRUE)
  macros <- c(
    macro_line("EpisodeCount", nrow(episodes)),
    macro_line("VictimCount", format(total_victims, big.mark = ",", trim = TRUE)),
    macro_line("CriminalCount", format(total_criminals, big.mark = ",", trim = TRUE)),
    macro_line("MajorCrimeEpisodeCount", sum(episodes$is_murder | episodes$is_rape | episodes$is_assault))
  )
  for (series in c("Original", "SVU", "Criminal Intent")) {
    prefix <- switch(series,
      Original = "Original",
      SVU = "Svu",
      "CriminalIntent"
    )
    macros <- c(macros, macro_line(paste0(prefix, "EpisodeCount"), sum(episodes$series == series)))
    for (role in c("victim", "criminal")) {
      for (group in c("white", "black", "hispanic", "female")) {
        value <- all$share_pct[all$series == series & all$role == role & all$group == group]
        name <- paste0(prefix, tools::toTitleCase(role), tools::toTitleCase(group), "Pct")
        macros <- c(macros, macro_line(name, sprintf("%.1f", value)))
      }
    }
  }
  lookup <- function(source, column, inverse = FALSE) {
    values <- source_tables[[source]]
    result <- values[[column]]
    if (inverse) result <- 100 - result
    sprintf("%.1f", mean(result, na.rm = TRUE))
  }
  macros <- c(
    macros,
    macro_line("NcvsSeriousBlackPct", lookup("ncvs_hispanic", "serious_violent_victimization_nh_black")),
    macro_line("NcvsRapeBlackPct", lookup("ncvs_hispanic", "rape_nh_black")),
    macro_line("NcvsAssaultBlackPct", lookup("ncvs_hispanic", "aggravated_assault_nh_black")),
    macro_line("UcrMurderVictimBlackPct", lookup("murder_victims", "murder_victim_black")),
    macro_line("NcvsSeriousFemalePct", lookup("ncvs", "serious_violent_victimization_male", inverse = TRUE)),
    macro_line("NcvsRapeFemalePct", lookup("ncvs", "rape_sexual_assault_male", inverse = TRUE)),
    macro_line("UcrMurderVictimFemalePct", lookup("murder_victims", "murder_victim_men", inverse = TRUE))
  )
  writeLines(macros, path)
}

write_tables <- function(aggregate, yearly, benchmarks, source_tables, episodes, table_dir) {
  catalog <- benchmark_catalog()
  for (role in c("victim", "criminal")) {
    for (group in c("female", "black")) {
      stem <- paste0(if (role == "victim") "v" else "c", "_", if (group == "female") "gender" else "race")
      table <- annual_table(yearly, source_tables, catalog, role, group)
      caption <- paste("Annual share of", group, role, "characters and historical comparisons")
      label <- paste0("tab:", if (role == "victim") "v" else "c", "_", if (group == "female") "sex" else "race")
      write_latex_table(table, file.path(table_dir, paste0(stem, ".tex")), caption, label)
      utils::write.csv(table, file.path(table_dir, paste0(stem, ".csv")), row.names = FALSE, na = "")
    }
  }
  write_macros(aggregate, benchmarks, episodes, source_tables, file.path(table_dir, "macros.tex"))
}
