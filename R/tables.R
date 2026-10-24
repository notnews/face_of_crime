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
  source_order <- c("ncvs", "ncvs_hispanic", "murder_victims", "ucr", "nyc", "nyc_arrests", "census")
  selected <- selected[order(match(selected$source, source_order)), ]
  for (i in seq_len(nrow(selected))) {
    item <- selected[i, ]
    source <- benchmarks[[item$source]]
    key <- item$label
    values <- source[[item$column]]
    if (group == "female" && !grepl("female_only", item$column) && item$source != "nyc_arrests") {
      values <- 100 - values
    }
    table[[key]] <- values[match(years, source$year)]
  }
  table
}

table_source <- function(header) {
  if (header %in% c("Criminal Intent", "Original", "SVU")) return("Coded episodes")
  if (grepl("^NCVS", header)) return("NCVS")
  if (grepl("^UCR", header)) return("UCR")
  if (grepl("^NYPD", header)) return("NYPD")
  "Census"
}

table_heading <- function(header) {
  if (header == "Criminal Intent") return("CI")
  if (header %in% c("Original", "SVU")) return(header)
  if (grepl("female-only offender", header)) return("Female-only")
  if (grepl("serious violence", header)) return("Serious")
  if (grepl("rape/sexual assault", header)) return("Rape/SA")
  if (grepl("aggravated assault", header)) return("Aggravated")
  if (grepl("murder victims", header)) return("Murder")
  if (grepl("all arrests", header)) return("All")
  if (grepl("violent arrests", header)) return("Violent")
  if (grepl("homicide", header)) return("Homicide")
  if (grepl("rape", header)) return("Rape")
  if (grepl("assault", header)) return("Assault")
  if (header == "US Census") return("US")
  if (header == "NY Census") return("NY")
  stop("Unknown table header: ", header)
}

write_latex_table <- function(table, path, caption, label, role, group) {
  headers <- names(table)[-1]
  sources <- vapply(headers, table_source, character(1))
  spans <- rle(sources)
  positions <- cumsum(c(2L, head(spans$lengths, -1L)))
  source_headers <- mapply(function(source, width) {
    paste0("\\multicolumn{", width, "}{c}{", source, "}")
  }, spans$values, spans$lengths, USE.NAMES = FALSE)
  source_rule <- mapply(function(start, width) {
    paste0("\\cmidrule(lr){", start, "-", start + width - 1L, "}")
  }, positions, spans$lengths, USE.NAMES = FALSE)
  detail <- paste(c("Year", vapply(headers, table_heading, character(1))), collapse = " & ")
  body <- apply(table, 1, function(row) {
    paste(c(row[1], format_percent(as.numeric(row[-1]))), collapse = " & ")
  })
  subject <- if (group == "black") "Black" else "female"
  show_note <- paste0("Coded columns: ", subject, " share of classified ", role, " characters")
  source_note <- if (role == "victim") {
    paste(
      "NCVS: weighted victimizations (serious = rape/sexual assault, robbery, and aggravated assault);",
      paste0("UCR: murder victims", if ("NYPD" %in% sources) "; NYPD: victims." else ".")
    )
  } else {
    paste(
      if ("NCVS" %in% sources) {
        "NCVS: female-only offenders in serious violence incidents with known offender sex (including mixed groups);"
      } else {
        ""
      },
      "UCR: arrests;",
      if ("NYPD" %in% sources) {
        if (group == "female") "NYPD: rape arrests." else "NYPD: suspects."
      } else {
        ""
      }
    )
  }
  race_note <- if (group == "black") {
    if ("NCVS" %in% sources) {
      "NCVS and NYPD Black exclude Hispanics; UCR Black includes Hispanics."
    } else {
      "NYPD Black excludes Hispanics; UCR Black includes Hispanics."
    }
  } else {
    ""
  }
  lines <- c(
    "\\begin{center}",
    paste0("\\captionof{table}{", caption, "}"),
    paste0("\\label{", label, "}"),
    "\\small",
    "\\setlength{\\tabcolsep}{3.5pt}",
    "\\renewcommand{\\arraystretch}{1.08}",
    paste0("\\begin{tabular}{@{}", paste(rep("r", ncol(table)), collapse = ""), "@{}}"),
    "\\toprule",
    paste0(" & ", paste(source_headers, collapse = " & "), " \\\\"),
    source_rule,
    paste0(detail, " \\\\"),
    "\\midrule",
    paste0(body, " \\\\"),
    "\\bottomrule", "\\end{tabular}",
    "\\par\\smallskip",
    paste0(
      "\\parbox{\\linewidth}{\\footnotesize ", show_note,
      " in episodes broadcast that year. ", source_note,
      " Census: population. ", race_note,
      " Entries are percentages; -- denotes no data.}"
    ),
    "\\end{center}"
  )
  writeLines(lines, path)
}

macro_line <- function(name, value) {
  paste0("\\newcommand{\\", name, "}{", value, "}")
}

write_macros <- function(aggregate, benchmarks, episodes, path) {
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
  point_macro <- function(prefix, source, column, group) {
    values <- benchmarks$share_pct[
      benchmarks$source == source & benchmarks$column == column & benchmarks$group == group
    ]
    stopifnot(length(values) == 1L)
    macro_line(paste0(prefix, "Pct"), sprintf("%.1f", values))
  }
  macros <- c(
    macros,
    point_macro("NcvsSeriousBlack", "ncvs_hispanic", "serious_violent_victimization_nh_black", "black"),
    point_macro("NcvsRapeBlack", "ncvs_hispanic", "rape_nh_black", "black"),
    point_macro("NcvsAssaultBlack", "ncvs_hispanic", "aggravated_assault_nh_black", "black"),
    point_macro("UcrMurderVictimBlack", "murder_victims", "murder_victim_black", "black"),
    point_macro("NcvsSeriousFemale", "ncvs", "serious_violent_victimization_male", "female"),
    point_macro("NcvsRapeFemale", "ncvs", "rape_sexual_assault_male", "female"),
    point_macro("UcrMurderVictimFemale", "murder_victims", "murder_victim_men", "female")
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
      write_latex_table(table, file.path(table_dir, paste0(stem, ".tex")), caption, label, role, group)
      utils::write.csv(table, file.path(table_dir, paste0(stem, ".csv")), row.names = FALSE, na = "")
    }
  }
  write_macros(aggregate, benchmarks, episodes, file.path(table_dir, "macros.tex"))
}
