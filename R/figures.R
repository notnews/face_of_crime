paper_theme <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.title.position = "plot"
    )
}

plot_aggregate_share <- function(shares, benchmarks, role, group) {
  show <- shares[
    shares$role == role & shares$group == group &
      (shares$crime_group != "rape" | shares$series == "SVU"),
  ]
  show$entity <- show$series
  show$comparison <- tools::toTitleCase(show$crime_group)

  reference <- benchmarks[benchmarks$role == role & benchmarks$group == group, ]
  reference <- reference[reference$source != "census", ]
  reference$entity <- reference$label
  reference$comparison <- "Historical benchmark"
  reference$share_pct <- reference$mean_pct

  points <- rbind(
    show[c("entity", "comparison", "share_pct")],
    reference[c("entity", "comparison", "share_pct")]
  )
  points$entity <- factor(points$entity, levels = rev(unique(points$entity)))
  label <- paste(tools::toTitleCase(group), if (role == "victim") "victims" else "criminals")

  ggplot2::ggplot(points, ggplot2::aes(x = entity, y = share_pct, colour = comparison)) +
    ggplot2::geom_point(size = 2.7, position = ggplot2::position_dodge(width = 0.55)) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
    ggplot2::labs(
      title = label, x = NULL, y = "Share of classified characters or records (%)",
      colour = NULL,
      caption = paste(
        "Show values count classified characters. Benchmarks average available years",
        "in the original source files; periods differ."
      )
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
      width = 7.5, height = 5.2, units = "in"
    )
  }
  ggplot2::ggsave(
    file.path(figure_dir, "all_criminals_by_race.png"), plots$all_criminals_by_race,
    width = 7.5, height = 5.2, units = "in", dpi = 180
  )
  invisible(names(plots))
}
