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
point_colours <- c(series_colours, "Historical Reference" = "#555555")

plot_aggregate_share <- function(shares, benchmarks, role, group) {
  show <- shares[shares$role == role & shares$group == group & shares$crime_group == "all", ]
  show$entity <- "Coded Episodes"
  show$legend <- show$series

  reference <- benchmarks[benchmarks$role == role & benchmarks$group == group, ]
  reference$entity <- gsub(" all ", " All ", tools::toTitleCase(reference$label), fixed = TRUE)
  reference$legend <- "Historical Reference"

  points <- rbind(
    show[c("entity", "share_pct", "legend")],
    reference[c("entity", "share_pct", "legend")]
  )
  points$entity <- factor(points$entity, levels = rev(unique(points$entity)))
  points$legend <- factor(points$legend, levels = names(point_colours))
  label <- paste(tools::toTitleCase(group), if (role == "victim") "victims" else "criminals")
  caption <- if (role == "victim") {
    paste(
      "Coded dots pool classified victim characters.",
      if (group == "hispanic") {
        "NCVS dots pool weighted victimizations (survey estimates; SEs not shown)."
      } else {
        "NCVS dots pool weighted victimizations (survey estimates; SEs not shown); UCR dots pool murder victims."
      },
      "Each gray reference dot pools available years in which any coded episode aired.",
      if (group == "black") "NCVS Black excludes Hispanics; UCR Black includes Hispanics." else "",
      sep = "\n"
    )
  } else if (group == "female") {
    paste(
      "Coded dots pool classified criminal characters. UCR dots pool arrests.",
      "NCVS: serious-violence incidents with victim-reported female-only offenders",
      "among known-sex incidents (SEs not shown);",
      "mixed-sex groups remain in the denominator.",
      "Each gray reference dot pools available years in which any coded episode aired.",
      sep = "\n"
    )
  } else {
    paste(
      "Coded dots pool classified criminal characters. UCR dots pool arrests.",
      "Each gray reference dot pools available years in which any coded episode aired.",
      if (group == "hispanic") {
        "UCR ethnicity counts begin in 2013 and cover arrests with reported ethnicity."
      } else {
        "UCR Black includes Hispanics."
      },
      sep = "\n"
    )
  }

  ggplot2::ggplot(points, ggplot2::aes(x = share_pct, y = entity, colour = legend)) +
    ggplot2::geom_point(
      data = points[points$legend != "Historical Reference", ],
      size = 2.8, position = ggplot2::position_dodge(width = 0.42, reverse = TRUE)
    ) +
    ggplot2::geom_point(
      data = points[points$legend == "Historical Reference", ], size = 2.8
    ) +
    ggplot2::scale_y_discrete(limits = levels(points$entity)) +
    ggplot2::scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
    ggplot2::scale_colour_manual(values = point_colours) +
    ggplot2::labs(
      title = label, x = "Share (%)", y = NULL, colour = NULL,
      caption = caption
    ) +
    paper_theme()
}

plot_yearly_share <- function(shares, role, group) {
  points <- shares[shares$role == role & shares$group == group, ]
  points$series <- factor(points$series, levels = c("Original", "SVU", "Criminal Intent"))
  points$run <- ifelse(points$series == "Original" & points$year < 2000, "original_early", as.character(points$series))
  label <- paste(tools::toTitleCase(group), if (role == "victim") "victims" else "criminals")
  ggplot2::ggplot(points, ggplot2::aes(x = year, y = share_pct, colour = series, group = run)) +
    ggplot2::geom_line(linewidth = 0.6, na.rm = TRUE) +
    ggplot2::geom_point(size = 1.8, na.rm = TRUE) +
    ggplot2::scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
    ggplot2::scale_x_continuous(breaks = seq(1990, 2016, 5)) +
    ggplot2::scale_colour_manual(values = series_colours) +
    ggplot2::labs(
      title = label, x = "Broadcast year", y = "Share of classified characters (%)",
      colour = NULL,
      caption = "Each annual value pools characters across coded episodes broadcast that year."
    ) +
    paper_theme()
}

write_figures <- function(aggregate, yearly, benchmarks, figure_dir) {
  plots <- list(
    all_victims_by_gender = plot_aggregate_share(aggregate, benchmarks, "victim", "female"),
    all_criminals_by_gender = plot_aggregate_share(aggregate, benchmarks, "criminal", "female"),
    all_victims_by_race = plot_aggregate_share(aggregate, benchmarks, "victim", "black"),
    all_criminals_by_race = plot_aggregate_share(aggregate, benchmarks, "criminal", "black"),
    all_victims_by_race_hispanic = plot_aggregate_share(aggregate, benchmarks, "victim", "hispanic"),
    all_criminals_by_race_hispanic = plot_aggregate_share(aggregate, benchmarks, "criminal", "hispanic"),
    all_victims_by_gender_ts = plot_yearly_share(yearly, "victim", "female"),
    all_criminals_by_gender_ts = plot_yearly_share(yearly, "criminal", "female"),
    all_victims_by_race_ts = plot_yearly_share(yearly, "victim", "black"),
    all_criminals_by_race_ts = plot_yearly_share(yearly, "criminal", "black")
  )
  for (name in names(plots)) {
    ggplot2::ggsave(
      file.path(figure_dir, paste0(name, ".pdf")), plots[[name]],
      width = 7.5, height = 6.1, units = "in"
    )
  }
  ggplot2::ggsave(
    file.path(figure_dir, "all_criminals_by_race.png"), plots$all_criminals_by_race,
    width = 7.5, height = 6.1, units = "in", dpi = 180
  )
  invisible(names(plots))
}
