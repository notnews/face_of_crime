paper_theme <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.caption = ggplot2::element_text(hjust = 0, size = 8)
    )
}

series_colours <- c(
  "Original" = "#0072B2",
  "SVU" = "#D55E00",
  "Criminal Intent" = "#009E73"
)
point_colours <- c(series_colours, "Reference" = "#555555")

plot_aggregate_share <- function(shares, benchmarks, role, group) {
  show <- shares[shares$role == role & shares$group == group & shares$crime_group == "all", ]
  show$entity <- show$series
  show$legend <- show$series

  reference <- benchmarks[benchmarks$role == role & benchmarks$group == group, ]
  reference$entity <- gsub(" all ", " All ", tools::toTitleCase(reference$label), fixed = TRUE)
  reference$legend <- "Reference"

  points <- rbind(
    show[c("entity", "share_pct", "legend")],
    reference[c("entity", "share_pct", "legend")]
  )
  points$entity <- factor(points$entity, levels = rev(c(names(series_colours), reference$entity)))
  points$legend <- factor(points$legend, levels = names(point_colours))
  label <- paste(tools::toTitleCase(group), if (role == "victim") "victims" else "criminals")
  axis_max <- min(100, 10 * ceiling(round(1.1 * max(points$share_pct), 6) / 10))
  caption <- if (role == "victim") {
    paste(
      "Colored dots pool classified victim characters.",
      if (group == "hispanic") {
        "NCVS dots pool weighted victimizations (survey estimates; SEs not shown)."
      } else {
        "NCVS dots pool weighted victimizations (survey estimates; SEs not shown); UCR dots pool murder victims."
      },
      if (group == "black") "NYPD dots pool victims with known race/ethnicity (2008–2015)." else "",
      "Each gray reference dot pools available years in which any coded episode aired.",
      if (group == "black") "NCVS and NYPD Black exclude Hispanics; UCR Black includes Hispanics." else "",
      sep = "\n"
    )
  } else if (group == "female") {
    paste(
      "Colored dots pool classified criminal characters. UCR dots pool arrests.",
      "NCVS: serious-violence incidents with victim-reported female-only offenders",
      "among known-sex incidents (SEs not shown);",
      "mixed-sex groups remain in the denominator.",
      "Each gray reference dot pools available years in which any coded episode aired.",
      sep = "\n"
    )
  } else {
    paste(
      if (group == "black") {
        paste0(
          "Colored dots pool classified criminal characters. UCR dots pool arrests; ",
          "NYPD dots pool suspects with known race/ethnicity."
        )
      } else {
        "Colored dots pool classified criminal characters. UCR dots pool arrests."
      },
      "Each gray reference dot pools available years in which any coded episode aired.",
      if (group == "hispanic") {
        "UCR ethnicity counts begin in 2013 and cover arrests with reported ethnicity."
      } else {
        "NYPD Black excludes Hispanics; UCR Black includes Hispanics."
      },
      sep = "\n"
    )
  }

  ggplot2::ggplot(points, ggplot2::aes(x = share_pct, y = entity, colour = legend)) +
    ggplot2::geom_point(size = 2.8) +
    ggplot2::scale_y_discrete(limits = levels(points$entity)) +
    ggplot2::scale_x_continuous(limits = c(0, axis_max), breaks = seq(0, axis_max, 10)) +
    ggplot2::scale_colour_manual(values = point_colours, guide = "none") +
    ggplot2::labs(
      title = label, x = "Share (%)", y = NULL,
      caption = caption
    ) +
    paper_theme() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_line(
        colour = "#D9D9D9", linewidth = 0.25, linetype = "dotted"
      )
    )
}

yearly_reference <- function(source_tables, years, role, group) {
  if (role == "victim") {
    source <- if (group == "black") source_tables$ncvs_hispanic else source_tables$ncvs
    value <- if (group == "black") {
      source$serious_violent_victimization_nh_black
    } else {
      100 - source$serious_violent_victimization_male
    }
    label <- "NCVS Serious Violence"
  } else {
    source <- source_tables$ucr
    value <- if (group == "black") source$violent_crime_perc_black else 100 - source$violent_crime_perc_men
    label <- "UCR Violent Arrests"
  }
  reference <- data.frame(year = source$year, share_pct = value, label = label)
  reference[reference$year %in% years & !is.na(reference$share_pct), ]
}

plot_yearly_share <- function(shares, source_tables, role, group) {
  points <- shares[shares$role == role & shares$group == group, ]
  points$series <- factor(points$series, levels = c("Original", "SVU", "Criminal Intent"))
  points$run <- ifelse(points$series == "Original" & points$year < 2000, "original_early", as.character(points$series))
  endpoints <- points[!is.na(points$share_pct), ]
  endpoints <- endpoints[ave(endpoints$year, endpoints$series, FUN = max) == endpoints$year, ]
  reference <- yearly_reference(source_tables, unique(points$year), role, group)
  reference_label <- reference[nrow(reference), ]
  reference_label$label_y <- reference_label$share_pct + if (role == "victim" && group == "black") {
    3
  } else if (role == "criminal" && group == "female") {
    -4
  } else {
    0
  }
  caption <- c(
    "Colored lines: share of classified characters in episodes broadcast each year.",
    if (role == "victim") {
      "Gray dashed line: NCVS share of weighted serious-violent victimizations (survey estimate; SEs not shown)."
    } else {
      "Gray dashed line: UCR share of violent-crime arrests."
    },
    if (group == "black") {
      if (role == "victim") "NCVS Black excludes Hispanics." else "UCR Black includes Hispanics."
    }
  )
  axis_values <- c(
    if (group == "black") shares$share_pct[shares$group == group] else points$share_pct,
    reference$share_pct
  )
  axis_max <- min(100, 10 * ceiling(round(1.1 * max(axis_values, na.rm = TRUE), 6) / 10))
  label <- paste(tools::toTitleCase(group), if (role == "victim") "victims" else "criminals")
  ggplot2::ggplot(points, ggplot2::aes(x = year, y = share_pct, colour = series, group = run)) +
    ggplot2::geom_line(
      data = reference, ggplot2::aes(x = year, y = share_pct), inherit.aes = FALSE,
      colour = "#666666", linetype = "dashed", linewidth = 0.55
    ) +
    ggplot2::geom_line(linewidth = 0.6, na.rm = TRUE) +
    ggplot2::geom_point(size = 1.8, na.rm = TRUE) +
    ggplot2::geom_text(
      data = endpoints, ggplot2::aes(x = year + 0.4, label = series),
      hjust = 0, size = 3, show.legend = FALSE
    ) +
    ggplot2::geom_segment(
      data = reference_label[reference_label$label_y != reference_label$share_pct, ],
      ggplot2::aes(x = year, y = share_pct, xend = year + 0.4, yend = label_y),
      inherit.aes = FALSE, colour = "#666666", linewidth = 0.35
    ) +
    ggplot2::geom_text(
      data = reference_label,
      ggplot2::aes(x = year + 0.4, y = label_y, label = label),
      inherit.aes = FALSE, colour = "#555555", hjust = 0, size = 3
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, axis_max), breaks = seq(0, axis_max, 10),
      expand = ggplot2::expansion(mult = c(0.03, 0.02))
    ) +
    ggplot2::scale_x_continuous(limits = c(1989.5, 2020), breaks = seq(1990, 2015, 5)) +
    ggplot2::scale_colour_manual(values = series_colours, guide = "none") +
    ggplot2::labs(
      title = label, x = "Broadcast year", y = "Share (%)",
      caption = paste(caption, collapse = "\n")
    ) +
    paper_theme()
}

write_figures <- function(aggregate, yearly, benchmarks, source_tables, figure_dir) {
  plots <- list(
    all_victims_by_gender = plot_aggregate_share(aggregate, benchmarks, "victim", "female"),
    all_criminals_by_gender = plot_aggregate_share(aggregate, benchmarks, "criminal", "female"),
    all_victims_by_race = plot_aggregate_share(aggregate, benchmarks, "victim", "black"),
    all_criminals_by_race = plot_aggregate_share(aggregate, benchmarks, "criminal", "black"),
    all_victims_by_race_hispanic = plot_aggregate_share(aggregate, benchmarks, "victim", "hispanic"),
    all_criminals_by_race_hispanic = plot_aggregate_share(aggregate, benchmarks, "criminal", "hispanic"),
    all_victims_by_gender_ts = plot_yearly_share(yearly, source_tables, "victim", "female"),
    all_criminals_by_gender_ts = plot_yearly_share(yearly, source_tables, "criminal", "female"),
    all_victims_by_race_ts = plot_yearly_share(yearly, source_tables, "victim", "black"),
    all_criminals_by_race_ts = plot_yearly_share(yearly, source_tables, "criminal", "black")
  )
  for (name in names(plots)) {
    is_aggregate <- !grepl("_ts$", name)
    height <- if (is_aggregate) 1.75 + 0.34 * nrow(plots[[name]]$data) else 6.1
    ggplot2::ggsave(
      file.path(figure_dir, paste0(name, ".pdf")), plots[[name]],
      width = 7.5, height = height, units = "in"
    )
  }
  ggplot2::ggsave(
    file.path(figure_dir, "all_criminals_by_race.png"), plots$all_criminals_by_race,
    width = 7.5, height = 1.75 + 0.34 * nrow(plots$all_criminals_by_race$data), units = "in", dpi = 180
  )
  invisible(names(plots))
}
